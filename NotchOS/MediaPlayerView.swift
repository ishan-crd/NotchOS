import SwiftUI

struct MediaPlayerView: View {
    @StateObject var vm: NotchViewModel
    @ObservedObject private var nowPlaying = NowPlayingManager.shared

    var body: some View {
        Group {
            if nowPlaying.hasNowPlaying {
                playerContent
            } else if nowPlaying.hasLastPlayed {
                lastPlayedState
            } else {
                skeletonState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: vm.cornerRadius))
    }

    // MARK: - Last Played

    var lastPlayedState: some View {
        HStack(spacing: 12) {
            Group {
                if let art = nowPlaying.lastArtwork {
                    Image(nsImage: art)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.white.opacity(0.06)
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .opacity(0.5)

            VStack(alignment: .leading, spacing: 4) {
                Text(nowPlaying.lastTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
                Text(nowPlaying.lastArtist)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.3))
                    .lineLimit(1)

                Spacer(minLength: 0)

                HStack(spacing: 14) {
                    Text("Last played")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.2))
                    Spacer(minLength: 0)
                    Button { nowPlaying.togglePlayPause() } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
    }

    // MARK: - Skeleton

    var skeletonState: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(0.06))
                .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 6) {
                Text("Nothing Playing")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.15))
                RoundedRectangle(cornerRadius: 3)
                    .fill(.white.opacity(0.05))
                    .frame(width: 80, height: 10)
                RoundedRectangle(cornerRadius: 3)
                    .fill(.white.opacity(0.04))
                    .frame(width: 60, height: 10)

                Spacer(minLength: 0)

                HStack(spacing: 20) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 14))
                    Image(systemName: "play.fill")
                        .font(.system(size: 18))
                    Image(systemName: "forward.fill")
                        .font(.system(size: 14))
                }
                .foregroundStyle(.white.opacity(0.1))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
    }

    var playerContent: some View {
        HStack(spacing: 12) {
            artworkView
            trackInfo
        }
        .padding(10)
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
