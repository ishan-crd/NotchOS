import Cocoa
import Combine

class NowPlayingManager: ObservableObject {
    static let shared = NowPlayingManager()

    @Published var title: String = ""
    @Published var artist: String = ""
    @Published var album: String = ""
    @Published var artwork: NSImage?
    @Published var isPlaying: Bool = false
    @Published var dominantColor: NSColor = .white
    @Published var hasNowPlaying: Bool = false
    @Published var position: Double = 0   // seconds
    @Published var duration: Double = 0   // seconds

    // Last played (retained when playback stops)
    @Published var lastTitle: String = ""
    @Published var lastArtist: String = ""
    @Published var lastAlbum: String = ""
    @Published var lastArtwork: NSImage?
    @Published var hasLastPlayed: Bool = false
    @Published var lastPlayedSource: String = "" // "spotify" or "music"

    @Published private(set) var spotifyAvailable: Bool = false
    @Published private(set) var musicAvailable: Bool = false
    private var appCheckCounter: Int = 0
    // Keep internal aliases
    var cachedSpotifyRunning: Bool { spotifyAvailable }
    var cachedMusicRunning: Bool { musicAvailable }

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
        appCheckCounter = 6 // force app re-check on notification
        fetchOnMainThread()
    }

    // MARK: - Fetching

    private func fetchOnMainThread() {
        // Re-check running apps every 6th poll (~30s) instead of every poll
        appCheckCounter += 1
        if appCheckCounter >= 6 || !hasNowPlaying {
            appCheckCounter = 0
            spotifyAvailable = NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.spotify.client" }
            musicAvailable = NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.apple.Music" }
        }

        let isSpotify = cachedSpotifyRunning
        let script = isSpotify ? spotifyScript : cachedMusicRunning ? musicScript : nil
        guard let script else {
            clearNowPlaying()
            return
        }
        if isSpotify { lastPlayedSource = "spotify" } else if cachedMusicRunning { lastPlayedSource = "music" }

        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.runScript(script)
        }
    }

    private func runScript(_ script: NSAppleScript?) {
        guard let script else { return }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        guard error == nil, let output = result.stringValue, !output.isEmpty else {
            DispatchQueue.main.async { self.clearNowPlaying() }
            return
        }
        DispatchQueue.main.async { self.parseResult(output) }
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
            // Only update when changed by ≥1s to avoid constant redraws
            if abs(position - newPos) >= 1 { position = newPos }
            if abs(duration - newDur) >= 1 { duration = newDur }
        }

        if artworkURL != lastArtworkURL {
            lastArtworkURL = artworkURL
            loadArtwork(from: artworkURL)
        }
    }

    private func loadArtwork(from urlString: String) {
        guard urlString != "none", !urlString.isEmpty, let url = URL(string: urlString) else { return }

        if let cached = artworkCache[urlString] {
            if artwork !== cached {
                artwork = cached
                dominantColor = Self.extractDominantColor(from: cached)
            }
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
                self.dominantColor = Self.extractDominantColor(from: image)
            }
        }.resume()
    }

    private static func extractDominantColor(from image: NSImage) -> NSColor {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let ciImage = CIImage(bitmapImageRep: bitmap)
        else { return .white }

        let extent = ciImage.extent
        // Sample center region for better color
        let cropRect = CGRect(
            x: extent.width * 0.25, y: extent.height * 0.25,
            width: extent.width * 0.5, height: extent.height * 0.5
        )
        let cropped = ciImage.cropped(to: cropRect)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [
            kCIInputImageKey: cropped,
            kCIInputExtentKey: CIVector(cgRect: cropped.extent)
        ]),
              let output = filter.outputImage
        else { return .white }

        var pixel = [UInt8](repeating: 0, count: 4)
        CIContext().render(output, toBitmap: &pixel, rowBytes: 4,
                           bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                           format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())

        let color = NSColor(
            red: CGFloat(pixel[0]) / 255,
            green: CGFloat(pixel[1]) / 255,
            blue: CGFloat(pixel[2]) / 255,
            alpha: 1
        )

        // Boost saturation and brightness so it's vibrant on dark background
        let h = color.hueComponent
        let s = min(color.saturationComponent * 1.4, 1.0)
        let b = max(color.brightnessComponent, 0.7)
        return NSColor(hue: h, saturation: s, brightness: b, alpha: 1)
    }

    private func clearNowPlaying() {
        guard hasNowPlaying else { return }
        // Save last played before clearing
        if !title.isEmpty {
            lastTitle = title
            lastArtist = artist
            lastAlbum = album
            lastArtwork = artwork
            hasLastPlayed = true
        }
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
        if cachedSpotifyRunning {
            executeScript("tell application \"Spotify\" to playpause")
        } else {
            executeScript("tell application \"Music\" to playpause")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.fetchOnMainThread()
        }
    }

    func nextTrack() {
        if cachedSpotifyRunning {
            executeScript("tell application \"Spotify\" to next track")
        } else {
            executeScript("tell application \"Music\" to next track")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.fetchOnMainThread()
        }
    }

    func previousTrack() {
        if cachedSpotifyRunning {
            executeScript("tell application \"Spotify\" to previous track")
        } else {
            executeScript("tell application \"Music\" to back track")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.fetchOnMainThread()
        }
    }

    func openLastPlayedApp() {
        if lastPlayedSource == "spotify" {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Spotify.app"))
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Music.app"))
        }
    }

    private func executeScript(_ source: String) {
        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
    }
}
