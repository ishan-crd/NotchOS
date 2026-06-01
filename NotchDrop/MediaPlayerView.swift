import SwiftUI

struct MediaPlayerView: View {
    @StateObject var vm: NotchViewModel
    @ObservedObject private var nowPlaying = NowPlayingManager.shared

    var body: some View {
        Group {
            if nowPlaying.hasNowPlaying {
                playerContent
            } else {
                emptyState
            }
        }
        .frame(maxHeight: .infinity)
        .frame(width: 240)
        .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius))
    }

    var emptyState: some View {
        RoundedRectangle(cornerRadius: vm.cornerRadius)
            .strokeBorder(style: StrokeStyle(lineWidth: 4, dash: [10]))
            .foregroundStyle(.white.opacity(0.1))
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "music.note")
                    Text("No Media Playing")
                        .font(.system(.headline, design: .rounded))
                }
            }
    }

    var playerContent: some View {
        HStack(spacing: 12) {
            artworkView
            trackInfo
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: vm.cornerRadius)
                .fill(.white.opacity(0.08))
        )
    }

    var artworkView: some View {
        Group {
            if let artwork = nowPlaying.artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Color.white.opacity(0.1)
                    Image(systemName: "music.note")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    var trackInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(nowPlaying.title)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)

            Text(nowPlaying.album)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(1)

            Text(nowPlaying.artist)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(1)

            Spacer(minLength: 0)

            controls
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var controls: some View {
        HStack(spacing: 20) {
            Button(action: { nowPlaying.previousTrack() }) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)

            Button(action: { nowPlaying.togglePlayPause() }) {
                Image(systemName: nowPlaying.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)

            Button(action: { nowPlaying.nextTrack() }) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white)
    }
}
