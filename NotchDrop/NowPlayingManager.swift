import Cocoa
import Combine

class NowPlayingManager: ObservableObject {
    static let shared = NowPlayingManager()

    @Published var title: String = ""
    @Published var artist: String = ""
    @Published var album: String = ""
    @Published var artwork: NSImage?
    @Published var isPlaying: Bool = false
    @Published var hasNowPlaying: Bool = false
    @Published var position: Double = 0   // seconds
    @Published var duration: Double = 0   // seconds

    private var artworkCache: [String: NSImage] = [:]
    private let maxCacheSize = 10
    private var lastArtworkURL: String = ""
    private var pollTimer: Timer?

    // Pre-compiled scripts (compiled once, executed many times)
    private var spotifyScript: NSAppleScript?
    private var musicScript: NSAppleScript?

    private init() {
        compileScripts()
    }

    func start() {
        guard pollTimer == nil else { return }
        setupNotifications()
        fetchOnMainThread()

        // Poll every 5 seconds as fallback — notifications handle most updates instantly
        pollTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.fetchOnMainThread()
        }
    }

    // MARK: - Pre-compiled Scripts

    private func compileScripts() {
        let spotifySource = """
        tell application "Spotify"
            if player state is stopped then return "STOPPED"
            set trackName to name of current track
            set trackArtist to artist of current track
            set trackAlbum to album of current track
            set artURL to artwork url of current track
            set pState to player state as string
            set pos to player position
            set dur to (duration of current track) / 1000
            return trackName & "||" & trackArtist & "||" & trackAlbum & "||" & artURL & "||" & pState & "||" & (pos as string) & "||" & (dur as string)
        end tell
        """
        let musicSource = """
        tell application "Music"
            if player state is stopped then return "STOPPED"
            set trackName to name of current track
            set trackArtist to artist of current track
            set trackAlbum to album of current track
            set pState to player state as string
            set pos to player position
            set dur to duration of current track
            return trackName & "||" & trackArtist & "||" & trackAlbum & "||none||" & pState & "||" & (pos as string) & "||" & (dur as string)
        end tell
        """
        spotifyScript = NSAppleScript(source: spotifySource)
        spotifyScript?.compileAndReturnError(nil)
        musicScript = NSAppleScript(source: musicSource)
        musicScript?.compileAndReturnError(nil)
    }

    // MARK: - Notifications (instant updates, no polling needed)

    private func setupNotifications() {
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(self, selector: #selector(handlePlaybackChange),
                        name: NSNotification.Name("com.spotify.client.PlaybackStateChanged"), object: nil)
        dnc.addObserver(self, selector: #selector(handlePlaybackChange),
                        name: NSNotification.Name("com.apple.Music.playerInfo"), object: nil)
    }

    @objc private func handlePlaybackChange(_ notification: Notification) {
        fetchOnMainThread()
    }

    // MARK: - Fetching

    private func fetchOnMainThread() {
        if isAppRunning("com.spotify.client") {
            runScript(spotifyScript)
        } else if isAppRunning("com.apple.Music") {
            runScript(musicScript)
        } else {
            clearNowPlaying()
        }
    }

    private func runScript(_ script: NSAppleScript?) {
        guard let script else { return }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        guard error == nil, let output = result.stringValue, !output.isEmpty else {
            clearNowPlaying()
            return
        }
        parseResult(output)
    }

    private func parseResult(_ result: String) {
        guard result != "STOPPED" else {
            clearNowPlaying()
            return
        }

        let parts = result.components(separatedBy: "||")
        guard parts.count >= 5 else { return }

        let newTitle = parts[0]
        let newArtist = parts[1]
        let newAlbum = parts[2]
        let artworkURL = parts[3]
        let newIsPlaying = parts[4].lowercased().contains("playing")

        // Only update published properties when values actually change
        if title != newTitle { title = newTitle }
        if artist != newArtist { artist = newArtist }
        if album != newAlbum { album = newAlbum }
        if isPlaying != newIsPlaying { isPlaying = newIsPlaying }
        if !hasNowPlaying { hasNowPlaying = true }

        if parts.count >= 7 {
            let newPos = Double(parts[5].trimmingCharacters(in: .whitespaces)) ?? 0
            let newDur = Double(parts[6].trimmingCharacters(in: .whitespaces)) ?? 0
            position = newPos
            duration = newDur
        }

        if artworkURL != lastArtworkURL {
            lastArtworkURL = artworkURL
            loadArtwork(from: artworkURL)
        }
    }

    private func loadArtwork(from urlString: String) {
        guard urlString != "none", !urlString.isEmpty, let url = URL(string: urlString) else { return }

        if let cached = artworkCache[urlString] {
            if artwork !== cached { artwork = cached }
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data, let image = NSImage(data: data) else { return }
            DispatchQueue.main.async {
                if self.artworkCache.count >= self.maxCacheSize {
                    self.artworkCache.removeAll()
                }
                self.artworkCache[urlString] = image
                self.artwork = image
            }
        }.resume()
    }

    private func clearNowPlaying() {
        guard hasNowPlaying else { return }
        title = ""
        artist = ""
        album = ""
        artwork = nil
        isPlaying = false
        hasNowPlaying = false
        position = 0
        duration = 0
        lastArtworkURL = ""
    }

    // MARK: - Playback Controls

    func togglePlayPause() {
        if isAppRunning("com.spotify.client") {
            executeScript("tell application \"Spotify\" to playpause")
        } else {
            executeScript("tell application \"Music\" to playpause")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.fetchOnMainThread()
        }
    }

    func nextTrack() {
        if isAppRunning("com.spotify.client") {
            executeScript("tell application \"Spotify\" to next track")
        } else {
            executeScript("tell application \"Music\" to next track")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.fetchOnMainThread()
        }
    }

    func previousTrack() {
        if isAppRunning("com.spotify.client") {
            executeScript("tell application \"Spotify\" to previous track")
        } else {
            executeScript("tell application \"Music\" to back track")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.fetchOnMainThread()
        }
    }

    private func isAppRunning(_ bundleId: String) -> Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == bundleId }
    }

    private func executeScript(_ source: String) {
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
    }
}
