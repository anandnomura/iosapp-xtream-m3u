import SwiftUI
import UIKit
import MobileVLCKit

final class VLCPlayerController: NSObject, ObservableObject, VLCMediaPlayerDelegate {
    @Published var errorMessage: String?
    @Published var stateDescription = "Ready"

    let mediaPlayer = VLCMediaPlayer()

    override init() {
        super.init()
        mediaPlayer.delegate = self
    }

    func play(url: URL) {
        errorMessage = nil
        stateDescription = "Opening stream..."

        let media = VLCMedia(url: url)
        media.addOption(":network-caching=1000")
        media.addOption(":live-caching=1000")
        mediaPlayer.media = media
        mediaPlayer.play()
    }

    func stop() {
        mediaPlayer.stop()
        stateDescription = "Stopped"
    }

    func mediaPlayerStateChanged(_ notification: Notification!) {
        let state = mediaPlayer.state

        DispatchQueue.main.async {
            switch state {
            case .opening:
                self.stateDescription = "Opening stream..."
            case .buffering:
                self.stateDescription = "Buffering..."
            case .playing:
                self.stateDescription = "Playing"
            case .paused:
                self.stateDescription = "Paused"
            case .stopped:
                self.stateDescription = "Stopped"
            case .ended:
                self.stateDescription = "Playback ended"
            case .error:
                self.stateDescription = "Playback failed"
                self.errorMessage = "VLC could not play this stream. The source is loading correctly, but the media format or server response still needs player-side compatibility work."
            default:
                self.stateDescription = "Ready"
            }
        }
    }
}

struct VLCVideoSurfaceView: UIViewRepresentable {
    let mediaPlayer: VLCMediaPlayer

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        view.clipsToBounds = true
        mediaPlayer.drawable = view
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if mediaPlayer.drawable !== uiView {
            mediaPlayer.drawable = uiView
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        uiView.layer.sublayers?.removeAll()
    }
}
