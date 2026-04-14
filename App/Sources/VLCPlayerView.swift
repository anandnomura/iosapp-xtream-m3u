import MobileVLCKit
import OSLog
import IPTVDomain
import SwiftUI
import UIKit

extension Notification.Name {
    static let emergencyStopPlayback = Notification.Name("app.emergencyStopPlayback")
}

@MainActor
struct PlayerTrackOption: Identifiable, Equatable {
    let id: Int
    let name: String
}

private struct StreamPlaybackProfile {
    let label: String
    let networkCachingMs: Int
    let liveCachingMs: Int
    let shouldForceTSDemux: Bool
    let bufferingRecoveryTimeoutSeconds: Double?
    let maxReconnectAttempts: Int
    let retryDelayMilliseconds: Int

    static func forSource(_ source: PlaybackSource) -> StreamPlaybackProfile {
        let hint = source.containerHint?.lowercased()
        let urlString = source.url.absoluteString.lowercased()

        if hint == "m3u8" || source.url.pathExtension.lowercased() == "m3u8" || urlString.contains(".m3u8") {
            return StreamPlaybackProfile(
                label: "HLS",
                networkCachingMs: 350,
                liveCachingMs: 350,
                shouldForceTSDemux: false,
                bufferingRecoveryTimeoutSeconds: nil,
                maxReconnectAttempts: 1,
                retryDelayMilliseconds: 150
            )
        }

        if hint == "ts" {
            return StreamPlaybackProfile(
                label: "MPEG-TS",
                networkCachingMs: 1600,
                liveCachingMs: 1600,
                shouldForceTSDemux: true,
                bufferingRecoveryTimeoutSeconds: 9,
                maxReconnectAttempts: 2,
                retryDelayMilliseconds: 500
            )
        }

        return StreamPlaybackProfile(
            label: "Standard",
            networkCachingMs: 900,
            liveCachingMs: 900,
            shouldForceTSDemux: false,
            bufferingRecoveryTimeoutSeconds: 6,
            maxReconnectAttempts: 2,
            retryDelayMilliseconds: 350
        )
    }
}

@MainActor
final class VLCPlayerController: NSObject, ObservableObject, @preconcurrency VLCMediaPlayerDelegate {
    @Published var errorMessage: String?
    @Published var stateDescription = "Ready"
    @Published var probeSummary: String?
    @Published var transportSummary: String?
    @Published private(set) var reconnectAttemptCount = 0
    @Published private(set) var audioTrackOptions: [PlayerTrackOption] = []
    @Published private(set) var subtitleTrackOptions: [PlayerTrackOption] = []
    @Published private(set) var selectedAudioTrackID: Int?
    @Published private(set) var selectedSubtitleTrackID: Int?
    @Published private(set) var currentSource: PlaybackSource?
    @Published private(set) var currentTitle = "1xtream-m3u"

    let mediaPlayer = VLCMediaPlayer()
    private let logger = Logger(subsystem: "com.bl.1xtream-m3u", category: "playback")
    private let session: URLSession
    private var bufferingRecoveryTask: Task<Void, Never>?
    private var probeTask: Task<Void, Never>?
    private var playbackSessionID = UUID()
    private var currentPlaybackProfile: StreamPlaybackProfile?

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
        playbackSessionID = UUID()
        let sessionID = playbackSessionID
        currentSource = source
        if let title {
            currentTitle = title
        }
        errorMessage = nil
        probeSummary = nil
        let profile = StreamPlaybackProfile.forSource(source)
        currentPlaybackProfile = profile
        transportSummary = "Profile: \(profile.label) • Cache \(profile.liveCachingMs)ms"
        stateDescription = "Opening stream..."
        logger.info("Starting playback title=\(self.currentTitle, privacy: .public) profile=\(profile.label, privacy: .public) url=\(source.url.absoluteString, privacy: .private(mask: .hash))")
        MediaSessionCoordinator.shared.updateNowPlaying(title: currentTitle, stateDescription: stateDescription)
        bufferingRecoveryTask?.cancel()
        probeTask?.cancel()

        let media = VLCMedia(url: source.url)
        media.addOption(":network-caching=\(profile.networkCachingMs)")
        media.addOption(":live-caching=\(profile.liveCachingMs)")
        media.addOption(":http-reconnect=true")
        media.addOption(":http-user-agent=1xtream-m3u/1.0")
        if profile.shouldForceTSDemux {
            media.addOption(":demux=ts")
        }
        mediaPlayer.media = media
        stateDescription = "Starting VLC..."
        MediaSessionCoordinator.shared.updateNowPlaying(title: currentTitle, stateDescription: stateDescription)
        mediaPlayer.play()

        probeTask = Task { [weak self] in
            guard let self else { return }

            let probeResult: String
            do {
                probeResult = try await self.probe(url: source.url)
            } catch {
                probeResult = "Probe warning: \(self.friendlyProbeMessage(for: error, url: source.url))"
            }

            await MainActor.run {
                guard self.playbackSessionID == sessionID,
                      self.currentSource?.url == source.url else {
                    return
                }

                self.probeSummary = probeResult
            }
        }
    }

    func stop() {
        mediaPlayer.stop()
        mediaPlayer.media = nil
        currentSource = nil
        currentPlaybackProfile = nil
        stateDescription = "Stopped"
        transportSummary = nil
        reconnectAttemptCount = 0
        audioTrackOptions = []
        subtitleTrackOptions = []
        selectedAudioTrackID = nil
        selectedSubtitleTrackID = nil
        bufferingRecoveryTask?.cancel()
        probeTask?.cancel()
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

        reconnectAttemptCount = 0
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

    func selectAudioTrack(_ option: PlayerTrackOption) {
        mediaPlayer.currentAudioTrackIndex = Int32(option.id)
        selectedAudioTrackID = option.id
    }

    func selectSubtitleTrack(_ option: PlayerTrackOption) {
        mediaPlayer.currentVideoSubTitleIndex = Int32(option.id)
        selectedSubtitleTrackID = option.id
    }

    nonisolated func mediaPlayerStateChanged(_ notification: Notification) {
        Task { @MainActor in
            let state = self.mediaPlayer.state
            self.logger.debug("Player state changed to \(String(describing: state.rawValue), privacy: .public)")
            switch state {
            case .opening:
                self.stateDescription = "Opening stream..."
                self.scheduleBufferingRecoveryIfNeeded()
            case .buffering:
                self.stateDescription = "Buffering..."
                self.scheduleBufferingRecoveryIfNeeded()
            case .playing:
                self.stateDescription = "Playing"
                if let profile = self.currentPlaybackProfile {
                    self.transportSummary = "Profile: \(profile.label)"
                } else {
                    self.transportSummary = nil
                }
                self.reconnectAttemptCount = 0
                self.bufferingRecoveryTask?.cancel()
                self.refreshTrackOptions()
            case .paused:
                self.stateDescription = "Paused"
                self.bufferingRecoveryTask?.cancel()
            case .stopped:
                self.stateDescription = "Stopped"
                self.transportSummary = nil
                self.bufferingRecoveryTask?.cancel()
            case .ended:
                self.stateDescription = "Playback ended"
                self.transportSummary = nil
                self.bufferingRecoveryTask?.cancel()
            case .error:
                self.bufferingRecoveryTask?.cancel()
                if self.reconnectAttemptCount < self.activeMaxReconnectAttempts,
                   self.currentSource != nil {
                    self.reconnectAttemptCount += 1
                    self.stateDescription = "Reconnecting..."
                    self.transportSummary = "Retry \(self.reconnectAttemptCount)/\(self.activeMaxReconnectAttempts) • \(self.currentPlaybackProfile?.label ?? "Default")"
                    self.logger.notice("Playback error; retry \(self.reconnectAttemptCount)/\(self.activeMaxReconnectAttempts) profile=\(self.currentPlaybackProfile?.label ?? "Default", privacy: .public)")
                    Task {
                        await self.retryCurrentStreamAfterDelay()
                    }
                    MediaSessionCoordinator.shared.updateNowPlaying(title: self.currentTitle, stateDescription: self.stateDescription)
                    return
                }

                self.stateDescription = "Playback failed"
                self.errorMessage = "VLC could not play this stream. The source is loading correctly, but the media format or server response still needs player-side compatibility work."
                self.transportSummary = "Stream recovery did not succeed."
                self.logger.error("Playback failed after retries profile=\(self.currentPlaybackProfile?.label ?? "Default", privacy: .public)")
            default:
                self.stateDescription = "Ready"
                self.bufferingRecoveryTask?.cancel()
            }
            MediaSessionCoordinator.shared.updateNowPlaying(title: self.currentTitle, stateDescription: self.stateDescription)
        }
    }

    private func scheduleBufferingRecoveryIfNeeded() {
        guard currentSource != nil else {
            return
        }

        guard let timeoutSeconds = currentPlaybackProfile?.bufferingRecoveryTimeoutSeconds else {
            bufferingRecoveryTask?.cancel()
            bufferingRecoveryTask = nil
            return
        }

        bufferingRecoveryTask?.cancel()
        bufferingRecoveryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(timeoutSeconds))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self,
                      self.currentSource != nil,
                      (self.stateDescription == "Buffering..." || self.stateDescription == "Opening stream..."),
                      self.reconnectAttemptCount < self.activeMaxReconnectAttempts else {
                    return
                }

                let stalledState = self.stateDescription
                self.reconnectAttemptCount += 1
                self.stateDescription = "Reconnecting..."
                self.transportSummary = "Retry \(self.reconnectAttemptCount)/\(self.activeMaxReconnectAttempts) • \(self.currentPlaybackProfile?.label ?? "Default")"
                self.logger.notice("Stalled in \(stalledState, privacy: .public); retry \(self.reconnectAttemptCount)/\(self.activeMaxReconnectAttempts) profile=\(self.currentPlaybackProfile?.label ?? "Default", privacy: .public)")

                Task {
                    await self.retryCurrentStreamAfterDelay()
                }
            }
        }
    }

    private func retryCurrentStreamAfterDelay() async {
        guard let currentSource else {
            return
        }

        let retryDelay = currentPlaybackProfile?.retryDelayMilliseconds ?? 350
        logger.debug("Retrying stream after \(retryDelay, privacy: .public)ms")
        try? await Task.sleep(for: .milliseconds(retryDelay))
        await startPlayback(source: currentSource, title: currentTitle)
    }

    private var activeMaxReconnectAttempts: Int {
        currentPlaybackProfile?.maxReconnectAttempts ?? 1
    }

    private func refreshTrackOptions() {
        audioTrackOptions = zipTrackOptions(names: mediaPlayer.audioTrackNames, indexes: mediaPlayer.audioTrackIndexes)
        subtitleTrackOptions = zipTrackOptions(names: mediaPlayer.videoSubTitlesNames, indexes: mediaPlayer.videoSubTitlesIndexes)
        selectedAudioTrackID = Int(mediaPlayer.currentAudioTrackIndex)
        selectedSubtitleTrackID = Int(mediaPlayer.currentVideoSubTitleIndex)
    }

    private func zipTrackOptions(names: [Any]?, indexes: [Any]?) -> [PlayerTrackOption] {
        guard let names, let indexes else {
            return []
        }

        let pairs = zip(names, indexes)
        return pairs.compactMap { nameAny, indexAny in
            let name = String(describing: nameAny)
            let trackID: Int

            if let number = indexAny as? NSNumber {
                trackID = number.intValue
            } else if let intValue = indexAny as? Int {
                trackID = intValue
            } else if let stringValue = indexAny as? String, let parsed = Int(stringValue) {
                trackID = parsed
            } else {
                return nil
            }

            return PlayerTrackOption(id: trackID, name: name)
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

        return "HTTP \(httpResponse.statusCode)"
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
        // VLC manages its own rendering subviews/layers. Manual teardown here can race
        // with VLCKit's cleanup and cause simulator crashes while removing the video view.
    }
}
