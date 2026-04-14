import AVKit
import MediaPlayer
import SwiftUI

@MainActor
final class MediaSessionCoordinator {
    static let shared = MediaSessionCoordinator()

    private var onPlay: (() -> Void)?
    private var onPause: (() -> Void)?
    private var onTogglePlayPause: (() -> Void)?
    private var onNextTrack: (() -> Void)?
    private var onPreviousTrack: (() -> Void)?

    private init() {}

    func configureRemoteCommands(
        onPlay: (() -> Void)? = nil,
        onPause: (() -> Void)? = nil,
        onTogglePlayPause: (() -> Void)? = nil,
        onNextTrack: (() -> Void)? = nil,
        onPreviousTrack: (() -> Void)? = nil
    ) {
        self.onPlay = onPlay
        self.onPause = onPause
        self.onTogglePlayPause = onTogglePlayPause
        self.onNextTrack = onNextTrack
        self.onPreviousTrack = onPreviousTrack

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = onPlay != nil
        commandCenter.pauseCommand.isEnabled = onPause != nil
        commandCenter.togglePlayPauseCommand.isEnabled = onTogglePlayPause != nil
        commandCenter.nextTrackCommand.isEnabled = onNextTrack != nil
        commandCenter.previousTrackCommand.isEnabled = onPreviousTrack != nil

        commandCenter.playCommand.removeTarget(nil)
        commandCenter.pauseCommand.removeTarget(nil)
        commandCenter.togglePlayPauseCommand.removeTarget(nil)
        commandCenter.nextTrackCommand.removeTarget(nil)
        commandCenter.previousTrackCommand.removeTarget(nil)

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self, let onPlay = self.onPlay else { return .commandFailed }
            onPlay()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self, let onPause = self.onPause else { return .commandFailed }
            onPause()
            return .success
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self, let onToggle = self.onTogglePlayPause else { return .commandFailed }
            onToggle()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self, let onNext = self.onNextTrack else { return .commandFailed }
            onNext()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self, let onPrevious = self.onPreviousTrack else { return .commandFailed }
            onPrevious()
            return .success
        }
    }

    func clearRemoteCommands() {
        configureRemoteCommands()
    }

    func updateNowPlaying(title: String, subtitle: String? = nil, stateDescription: String) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue
        ]

        if let subtitle, !subtitle.isEmpty {
            info[MPMediaItemPropertyArtist] = subtitle
        }

        switch stateDescription {
        case "Playing":
            info[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        case "Paused":
            info[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
        default:
            info[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
}

struct AirPlayRoutePicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.prioritizesVideoDevices = true
        view.activeTintColor = UIColor(AppPalette.mint)
        view.tintColor = UIColor.white
        return view
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
