import Combine
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
    @Published private(set) var savedProfiles: [SavedProfileRecord] = []
    @Published private(set) var favorites: [MediaItem] = []
    @Published private(set) var recents: [MediaItem] = []
    @Published private(set) var groups: [MediaGroup] = []
    @Published private(set) var items: [MediaItem] = []
    @Published private(set) var lastUpdatedAt: Date?
    @Published private(set) var statusMessage = "Choose a source and load your channels."
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let m3uLoader: M3UPlaylistLoader
    private let xtreamLoader: XtreamLivePlaylistLoader
    private let persistence: AppPersistence
    private var cancellables: Set<AnyCancellable> = []

    init(
        m3uLoader: M3UPlaylistLoader = M3UPlaylistLoader(),
        xtreamLoader: XtreamLivePlaylistLoader = XtreamLivePlaylistLoader(),
        persistence: AppPersistence = .shared
    ) {
        self.m3uLoader = m3uLoader
        self.xtreamLoader = xtreamLoader
        self.persistence = persistence
        restorePersistedState()
        bindDraftPersistence()
    }

    func loadChannels() async {
        let profile = try? buildProfile()
        await loadChannels(using: profile)
    }

    func loadChannels(using profileOverride: ProviderProfile?) async {
        isLoading = true
        errorMessage = nil
        statusMessage = "Loading channels..."

        do {
            let profile = try profileOverride ?? buildProfile()
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

            applyLoadedPlaylist(parsed, for: profile, markAsActive: true)
            statusMessage = "Loaded \(parsed.items.count) channels across \(parsed.groups.count) groups."
        } catch {
            errorMessage = friendlyMessage(for: error)
            statusMessage = "Unable to load channels."
        }

        isLoading = false
    }

    func refreshActiveProfile() async {
        guard let activeProfile else {
            statusMessage = "Choose or save a profile first."
            return
        }

        await loadChannels(using: activeProfile)
    }

    func selectProfile(_ record: SavedProfileRecord) {
        activeProfile = record.profile
        groups = record.groups
        items = record.items.map(markFavoriteIfNeeded)
        lastUpdatedAt = record.lastUpdatedAt
        statusMessage = record.groups.isEmpty
            ? "Profile selected. Load or refresh to fetch channels."
            : "Loaded cached channels for \(record.profile.name)."
        errorMessage = nil

        populateInputs(from: record.profile)
        markProfileOpened(record.profile.id)
        persistence.saveActiveProfileID(record.profile.id)
    }

    func deleteProfiles(at offsets: IndexSet) {
        let ids = offsets.map { savedProfiles[$0].id }
        for index in offsets.sorted(by: >) {
            savedProfiles.remove(at: index)
        }
        persistence.saveProfiles(savedProfiles)
        persistence.deleteProfileSecrets(ids: ids)

        if let activeProfile, ids.contains(activeProfile.id) {
            self.activeProfile = nil
            groups = []
            items = []
            lastUpdatedAt = nil
            persistence.saveActiveProfileID(nil)
            statusMessage = "Profile removed."
        }
    }

    func items(in group: MediaGroup) -> [MediaItem] {
        items.filter { $0.groupID == group.id }
    }

    func isFavorite(_ item: MediaItem) -> Bool {
        favorites.contains(where: { favorite in
            favorite.id == item.id && favorite.providerID == item.providerID
        })
    }

    func toggleFavorite(_ item: MediaItem) {
        let key = favoriteKey(for: item)

        if let index = favorites.firstIndex(where: { favoriteKey(for: $0) == key }) {
            favorites.remove(at: index)
        } else {
            var favoriteItem = item
            favoriteItem.isFavorite = true
            favorites.insert(favoriteItem, at: 0)
        }

        persistence.saveFavorites(favorites)
        applyFavoriteFlagsAcrossState()
    }

    func registerRecent(_ item: MediaItem) {
        recents.removeAll(where: { recent in
            recent.id == item.id && recent.providerID == item.providerID
        })
        recents.insert(item, at: 0)
        recents = Array(recents.prefix(12))
        persistence.saveRecents(recents)
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

            if let existing = matchingSavedProfile(kind: .m3u, remoteURL: url, rawText: nil, host: nil, username: nil, password: nil) {
                var updated = existing.profile
                updated.name = finalName
                updated.playlistSource = PlaylistSource(remoteURL: url)
                return updated
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

            if let existing = matchingSavedProfile(kind: .m3u, remoteURL: nil, rawText: text, host: nil, username: nil, password: nil) {
                var updated = existing.profile
                updated.name = finalName
                updated.playlistSource = PlaylistSource(rawText: text)
                return updated
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

            if let existing = matchingSavedProfile(kind: .xtream, remoteURL: nil, rawText: nil, host: host, username: username, password: password) {
                var updated = existing.profile
                updated.name = finalName
                updated.xtreamCredentials = XtreamCredentials(host: host, username: username, password: password)
                return updated
            }

            return ProviderProfile(
                name: finalName,
                kind: .xtream,
                xtreamCredentials: XtreamCredentials(host: host, username: username, password: password)
            )
        }
    }

    private func applyLoadedPlaylist(_ parsed: ParsedPlaylist, for profile: ProviderProfile, markAsActive: Bool) {
        if markAsActive {
            activeProfile = profile
        }

        groups = parsed.groups
        items = parsed.items.map(markFavoriteIfNeeded)
        lastUpdatedAt = .now
        upsertSavedProfile(
            SavedProfileRecord(
                profile: profile,
                groups: parsed.groups,
                items: items,
                lastUpdatedAt: .now,
                lastOpenedAt: .now
            )
        )
        populateInputs(from: profile)
        persistence.saveActiveProfileID(profile.id)
    }

    private func bindDraftPersistence() {
        Publishers.CombineLatest4($sourceMode, $profileName, $m3uURLString, $rawM3UText)
            .combineLatest(Publishers.CombineLatest3($xtreamHostString, $xtreamUsername, $xtreamPassword))
            .sink { [weak self] lhs, rhs in
                guard let self else { return }

                let draft = SourceDraft(
                    sourceMode: lhs.0.rawValue,
                    profileName: lhs.1,
                    m3uURLString: lhs.2,
                    rawM3UText: lhs.3,
                    xtreamHostString: rhs.0,
                    xtreamUsername: rhs.1,
                    xtreamPassword: rhs.2
                )
                self.persistence.saveDraft(draft)
            }
            .store(in: &cancellables)
    }

    private func restorePersistedState() {
        savedProfiles = persistence.loadProfiles()
        favorites = persistence.loadFavorites()
        recents = persistence.loadRecents()

        if let draft = persistence.loadDraft() {
            sourceMode = SourceMode(rawValue: draft.sourceMode) ?? .m3uURL
            profileName = draft.profileName
            m3uURLString = draft.m3uURLString
            rawM3UText = draft.rawM3UText
            xtreamHostString = draft.xtreamHostString
            xtreamUsername = draft.xtreamUsername
            xtreamPassword = draft.xtreamPassword
        }

        if let activeID = persistence.loadActiveProfileID(),
           let record = savedProfiles.first(where: { $0.id == activeID }) {
            selectProfile(record)
        }

        applyFavoriteFlagsAcrossState()
    }

    private func populateInputs(from profile: ProviderProfile) {
        profileName = profile.name

        switch profile.kind {
        case .m3u:
            sourceMode = .m3uURL
            m3uURLString = profile.playlistSource?.remoteURL?.absoluteString ?? ""
            rawM3UText = profile.playlistSource?.rawText ?? ""
            if profile.playlistSource?.remoteURL == nil, !(profile.playlistSource?.rawText?.isEmpty ?? true) {
                sourceMode = .m3uText
            }
            xtreamHostString = ""
            xtreamUsername = ""
            xtreamPassword = ""

        case .xtream:
            sourceMode = .xtream
            m3uURLString = ""
            rawM3UText = ""
            xtreamHostString = profile.xtreamCredentials?.host.absoluteString ?? ""
            xtreamUsername = profile.xtreamCredentials?.username ?? ""
            xtreamPassword = profile.xtreamCredentials?.password ?? ""
        }
    }

    private func upsertSavedProfile(_ record: SavedProfileRecord) {
        savedProfiles.removeAll(where: { $0.id == record.id })
        savedProfiles.insert(record, at: 0)
        persistence.saveProfiles(savedProfiles)
    }

    private func markProfileOpened(_ id: UUID) {
        guard let index = savedProfiles.firstIndex(where: { $0.id == id }) else {
            return
        }

        savedProfiles[index].lastOpenedAt = .now
        let record = savedProfiles.remove(at: index)
        savedProfiles.insert(record, at: 0)
        persistence.saveProfiles(savedProfiles)
    }

    private func matchingSavedProfile(
        kind: ProviderKind,
        remoteURL: URL?,
        rawText: String?,
        host: URL?,
        username: String?,
        password: String?
    ) -> SavedProfileRecord? {
        savedProfiles.first { record in
            guard record.profile.kind == kind else {
                return false
            }

            switch kind {
            case .m3u:
                if let remoteURL {
                    return record.profile.playlistSource?.remoteURL == remoteURL
                }

                if let rawText {
                    return record.profile.playlistSource?.rawText == rawText
                }

                return false

            case .xtream:
                return record.profile.xtreamCredentials?.host == host
                    && record.profile.xtreamCredentials?.username == username
                    && (password == nil || record.profile.xtreamCredentials?.password == password)
            }
        }
    }

    private func favoriteKey(for item: MediaItem) -> String {
        "\(item.providerID.uuidString)::\(item.id)"
    }

    private func markFavoriteIfNeeded(_ item: MediaItem) -> MediaItem {
        var updated = item
        updated.isFavorite = isFavorite(item)
        return updated
    }

    private func applyFavoriteFlagsAcrossState() {
        items = items.map(markFavoriteIfNeeded)
        recents = recents.map(markFavoriteIfNeeded)
        favorites = favorites.map(markFavoriteIfNeeded)

        savedProfiles = savedProfiles.map { record in
            var updated = record
            updated.items = record.items.map(markFavoriteIfNeeded)
            return updated
        }

        persistence.saveFavorites(favorites)
        persistence.saveRecents(recents)
        persistence.saveProfiles(savedProfiles)
    }

    private func friendlyMessage(for error: Error) -> String {
        let nsError = error as NSError

        if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorAppTransportSecurityRequiresSecureConnection {
            let failingURL = nsError.userInfo[NSURLErrorFailingURLErrorKey] as? URL
            let failingString = failingURL?.absoluteString ?? "unknown URL"
            return "ATS blocked an insecure request for \(failingString). This build should allow common IPTV HTTP sources, so if this persists we need to inspect the exact redirected host."
        }

        if let remotePlaylistError = error as? RemotePlaylistError {
            switch remotePlaylistError.kind {
            case .invalidPlaylist:
                let preview = remotePlaylistError.responsePreview ?? "No preview available."
                return "The provider URL did respond, but it did not return clean M3U text. Preview: \(preview)"
            case .invalidStatus:
                return remotePlaylistError.errorDescription ?? "The playlist server returned an unexpected response."
            case .unsupportedEncoding:
                return remotePlaylistError.errorDescription ?? "The playlist server returned unreadable text."
            case .network:
                return remotePlaylistError.errorDescription ?? "The playlist server could not be reached."
            }
        }

        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return description
        }

        if let parserError = error as? M3UParserError, parserError == .missingHeader {
            return "The M3U content must begin with #EXTM3U."
        }

        return error.localizedDescription
    }
}
