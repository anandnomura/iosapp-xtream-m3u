import MobileVLCKit
import IPTVDomain
import SwiftUI
import UIKit

extension Notification.Name {
    static let emergencyStopPlayback = Notification.Name("app.emergencyStopPlayback")
}

@MainActor
final class VLCPlayerController: NSObject, ObservableObject, @preconcurrency VLCMediaPlayerDelegate {
    @Published var errorMessage: String?
    @Published var stateDescription = "Ready"
    @Published var probeSummary: String?
    @Published private(set) var currentSource: PlaybackSource?
    @Published private(set) var currentTitle = "1xtream-m3u"

    let mediaPlayer = VLCMediaPlayer()
    private let session: URLSession

    override init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 12
        configuration.timeoutIntervalForResource = 12
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: configuration)
        super.init()
        mediaPlayer.delegate = self
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEmergencyStopPlayback),
            name: .emergencyStopPlayback,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func startPlayback(source: PlaybackSource, title: String? = nil) async {
        currentSource = source
        if let title {
            currentTitle = title
        }
        errorMessage = nil
        probeSummary = nil
        stateDescription = "Opening stream..."
        MediaSessionCoordinator.shared.updateNowPlaying(title: currentTitle, stateDescription: stateDescription)

        do {
            probeSummary = try await probe(url: source.url)
        } catch {
            probeSummary = "Probe warning: \(friendlyProbeMessage(for: error, url: source.url))"
        }

        let media = VLCMedia(url: source.url)
        media.addOption(":network-caching=1200")
        media.addOption(":live-caching=1200")
        media.addOption(":http-reconnect=true")
        media.addOption(":http-user-agent=1xtream-m3u/1.0")
        if let hint = source.containerHint?.lowercased(), hint == "ts" {
            media.addOption(":demux=ts")
        }
        mediaPlayer.media = media
        stateDescription = "Starting VLC..."
        MediaSessionCoordinator.shared.updateNowPlaying(title: currentTitle, stateDescription: stateDescription)
        mediaPlayer.play()
    }

    func stop() {
        mediaPlayer.stop()
        mediaPlayer.media = nil
        currentSource = nil
        stateDescription = "Stopped"
        MediaSessionCoordinator.shared.clearNowPlaying()
    }

    func detachOutput() {
        mediaPlayer.drawable = nil
    }

    @objc private func handleEmergencyStopPlayback() {
        stop()
        detachOutput()
    }

    func retryPlayback() async {
        guard let currentSource else {
            return
        }

        await startPlayback(source: currentSource, title: currentTitle)
    }

    func pausePlayback() {
        mediaPlayer.pause()
        stateDescription = "Paused"
        MediaSessionCoordinator.shared.updateNowPlaying(title: currentTitle, stateDescription: stateDescription)
    }

    func resumePlayback() {
        mediaPlayer.play()
        stateDescription = "Starting VLC..."
        MediaSessionCoordinator.shared.updateNowPlaying(title: currentTitle, stateDescription: stateDescription)
    }

    func togglePlayPause() {
        switch mediaPlayer.state {
        case .playing, .buffering, .opening:
            pausePlayback()
        default:
            resumePlayback()
        }
    }

    nonisolated func mediaPlayerStateChanged(_ notification: Notification) {
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
            MediaSessionCoordinator.shared.updateNowPlaying(title: self.currentTitle, stateDescription: self.stateDescription)
        }
    }

    private func probe(url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue("bytes=0-1023", forHTTPHeaderField: "Range")
        request.setValue("1xtream-m3u/1.0", forHTTPHeaderField: "User-Agent")

        let (bytes, response) = try await session.bytes(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            return "Loaded response"
        }

        guard 200..<400 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        for try await _ in bytes.prefix(1) {
            break
        }

        return "Stream reachable: HTTP \(httpResponse.statusCode)"
    }

    private func friendlyProbeMessage(for error: Error, url: URL) -> String {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorCannotFindHost:
                return "The stream host could not be found for \(url.host ?? url.absoluteString)."
            case NSURLErrorCannotConnectToHost:
                return "The app reached the host name, but could not connect to the stream server."
            case NSURLErrorTimedOut:
                return "The stream server timed out before sending playable data."
            case NSURLErrorAppTransportSecurityRequiresSecureConnection:
                return "Apple networking blocked \(url.absoluteString), but VLC will still attempt playback."
            default:
                return error.localizedDescription
            }
        }

        return error.localizedDescription
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
        if (mediaPlayer.drawable as AnyObject?) !== uiView {
            mediaPlayer.drawable = uiView
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        uiView.layer.sublayers?.removeAll()
    }
}
