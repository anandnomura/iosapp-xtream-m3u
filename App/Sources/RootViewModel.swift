import Foundation
import IPTVDomain
import IPTVData

@MainActor
final class RootViewModel: ObservableObject {
    enum SourceMode: String, CaseIterable, Identifiable {
        case m3uURL = "M3U URL"
        case m3uText = "M3U Text"
        case xtream = "Xtream"

        var id: String { rawValue }
    }

    @Published var sourceMode: SourceMode = .m3uURL
    @Published var profileName = "My Playlist"
    @Published var m3uURLString = ""
    @Published var rawM3UText = ""
    @Published var xtreamHostString = ""
    @Published var xtreamUsername = ""
    @Published var xtreamPassword = ""

    @Published private(set) var activeProfile: ProviderProfile?
    @Published private(set) var groups: [MediaGroup] = []
    @Published private(set) var items: [MediaItem] = []
    @Published private(set) var statusMessage = "Choose a source and load your channels."
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let m3uLoader: M3UPlaylistLoader
    private let xtreamLoader: XtreamLivePlaylistLoader

    init(
        m3uLoader: M3UPlaylistLoader = M3UPlaylistLoader(),
        xtreamLoader: XtreamLivePlaylistLoader = XtreamLivePlaylistLoader()
    ) {
        self.m3uLoader = m3uLoader
        self.xtreamLoader = xtreamLoader
    }

    func loadChannels() async {
        isLoading = true
        errorMessage = nil
        statusMessage = "Loading channels..."

        do {
            let profile = try buildProfile()
            let parsed: ParsedPlaylist

            switch profile.kind {
            case .m3u:
                guard let playlistSource = profile.playlistSource else {
                    throw PlaylistLoaderError.missingSource
                }
                parsed = try await m3uLoader.load(source: playlistSource, providerID: profile.id)

            case .xtream:
                guard let credentials = profile.xtreamCredentials else {
                    throw PlaylistLoaderError.emptyCredentials
                }
                parsed = try await xtreamLoader.load(credentials: credentials, providerID: profile.id)
            }

            activeProfile = profile
            groups = parsed.groups
            items = parsed.items
            statusMessage = "Loaded \(parsed.items.count) channels across \(parsed.groups.count) groups."
        } catch {
            activeProfile = nil
            groups = []
            items = []
            errorMessage = friendlyMessage(for: error)
            statusMessage = "Unable to load channels."
        }

        isLoading = false
    }

    func items(in group: MediaGroup) -> [MediaItem] {
        items.filter { $0.groupID == group.id }
    }

    private func buildProfile() throws -> ProviderProfile {
        let trimmedName = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.isEmpty ? "My Playlist" : trimmedName

        switch sourceMode {
        case .m3uURL:
            guard let url = URL(string: m3uURLString.trimmingCharacters(in: .whitespacesAndNewlines)),
                  ["http", "https"].contains(url.scheme?.lowercased() ?? "")
            else {
                throw PlaylistLoaderError.invalidURL
            }

            return ProviderProfile(
                name: finalName,
                kind: .m3u,
                playlistSource: PlaylistSource(remoteURL: url)
            )

        case .m3uText:
            let text = rawM3UText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else {
                throw PlaylistLoaderError.missingSource
            }

            return ProviderProfile(
                name: finalName,
                kind: .m3u,
                playlistSource: PlaylistSource(rawText: text)
            )

        case .xtream:
            let hostText = xtreamHostString.trimmingCharacters(in: .whitespacesAndNewlines)
            let username = xtreamUsername.trimmingCharacters(in: .whitespacesAndNewlines)
            let password = xtreamPassword.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !hostText.isEmpty, !username.isEmpty, !password.isEmpty else {
                throw PlaylistLoaderError.emptyCredentials
            }

            let normalizedHost = hostText.contains("://") ? hostText : "https://\(hostText)"
            guard let host = URL(string: normalizedHost) else {
                throw PlaylistLoaderError.invalidURL
            }

            return ProviderProfile(
                name: finalName,
                kind: .xtream,
                xtreamCredentials: XtreamCredentials(host: host, username: username, password: password)
            )
        }
    }

    private func friendlyMessage(for error: Error) -> String {
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return description
        }

        if let parserError = error as? M3UParserError, parserError == .missingHeader {
            return "The M3U content must begin with #EXTM3U."
        }

        return error.localizedDescription
    }
}
