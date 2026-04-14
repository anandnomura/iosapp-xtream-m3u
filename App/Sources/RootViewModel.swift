import Combine
import Foundation
import IPTVDomain
import IPTVData

@MainActor
final class RootViewModel: ObservableObject {
    enum SourceMode: String, CaseIterable, Identifiable {
        case m3u = "M3U"
        case xtream = "Xtream"

        var id: String { rawValue }
    }

    @Published var sourceMode: SourceMode = .m3u
    @Published var profileName = "My Playlist"
    @Published var m3uURLString = ""
    @Published var guideURLString = ""
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
    @Published private(set) var guideStatusMessage: String?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private var itemsByGroupID: [String: [MediaItem]] = [:]
    private var groupCountsByID: [String: Int] = [:]
    private var groupNamesByID: [String: String] = [:]
    private var sortedGroupsByItemCount: [MediaGroup] = []
    private var searchableTextByItemKey: [String: String] = [:]
    private let m3uLoader: M3UPlaylistLoader
    private let xtreamLoader: XtreamLivePlaylistLoader
    private let guideLoader: XMLTVGuideLoader
    private let epgMatcher: EPGMatcher
    private let persistence: AppPersistence
    private var nowNextByProfileID: [UUID: [String: ChannelNowNext]] = [:]
    private var cancellables: Set<AnyCancellable> = []

    init(
        m3uLoader: M3UPlaylistLoader = M3UPlaylistLoader(),
        xtreamLoader: XtreamLivePlaylistLoader = XtreamLivePlaylistLoader(),
        guideLoader: XMLTVGuideLoader = XMLTVGuideLoader(),
        epgMatcher: EPGMatcher = EPGMatcher(),
        persistence: AppPersistence = .shared
    ) {
        self.m3uLoader = m3uLoader
        self.xtreamLoader = xtreamLoader
        self.guideLoader = guideLoader
        self.epgMatcher = epgMatcher
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
            await reloadGuideIfAvailable(for: profile, items: parsed.items)
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
        rebuildItemIndexes()
        lastUpdatedAt = record.lastUpdatedAt
        statusMessage = record.groups.isEmpty
            ? "Profile selected. Load or refresh to fetch channels."
            : "Loaded cached channels for \(record.profile.name)."
        errorMessage = nil

        populateInputs(from: record.profile)
        markProfileOpened(record.profile.id)
        persistence.saveActiveProfileID(record.profile.id)

        if let cached = nowNextByProfileID[record.id], !cached.isEmpty {
            guideStatusMessage = "Guide matched \(cached.count) channels."
        } else {
            guideStatusMessage = nil
        }

        Task {
            await reloadGuideIfAvailable(for: record.profile, items: record.items)
        }
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
            rebuildItemIndexes()
            lastUpdatedAt = nil
            persistence.saveActiveProfileID(nil)
            statusMessage = "Profile removed."
        }
    }

    func items(in group: MediaGroup) -> [MediaItem] {
        itemsByGroupID[group.id] ?? []
    }

    func itemCount(in group: MediaGroup) -> Int {
        groupCountsByID[group.id] ?? 0
    }

    func groupsForDisplay() -> [MediaGroup] {
        sortedGroupsByItemCount
    }

    func searchItems(matching term: String) -> [MediaItem] {
        let normalizedTerm = normalizedSearchText(term)
        guard !normalizedTerm.isEmpty else {
            return []
        }

        return items.filter { item in
            searchableTextByItemKey[searchKey(for: item)]?.contains(normalizedTerm) == true
        }
    }

    func nowNext(for item: MediaItem) -> ChannelNowNext? {
        nowNextByProfileID[item.providerID]?[item.id]
    }

    func lastPlayedItem(for profile: ProviderProfile) -> MediaItem? {
        guard let record = savedProfiles.first(where: { $0.id == profile.id }),
              let itemID = record.lastPlayedItemID else {
            return nil
        }

        return record.items.first(where: { $0.id == itemID })
    }

    func lastSelectedGroup(for profile: ProviderProfile) -> MediaGroup? {
        guard let record = savedProfiles.first(where: { $0.id == profile.id }),
              let groupID = record.lastSelectedGroupID else {
            return nil
        }

        return record.groups.first(where: { $0.id == groupID })
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
        markLastPlayed(item)
    }

    func recordGroupVisit(_ group: MediaGroup) {
        guard let activeProfile else {
            return
        }

        guard let index = savedProfiles.firstIndex(where: { $0.id == activeProfile.id }) else {
            return
        }

        savedProfiles[index].lastSelectedGroupID = group.id
        persistence.saveProfiles(savedProfiles)
    }

    private func buildProfile() throws -> ProviderProfile {
        let trimmedName = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.isEmpty ? "My Playlist" : trimmedName

        switch sourceMode {
        case .m3u:
            guard let url = URL(string: m3uURLString.trimmingCharacters(in: .whitespacesAndNewlines)),
                  ["http", "https"].contains(url.scheme?.lowercased() ?? "")
            else {
                throw PlaylistLoaderError.invalidURL
            }

            if let existing = matchingSavedProfile(kind: .m3u, remoteURL: url, rawText: nil, host: nil, username: nil, password: nil) {
                var updated = existing.profile
                updated.name = finalName
                updated.playlistSource = PlaylistSource(remoteURL: url)
                updated.xmltvSource = parsedGuideSource()
                return updated
            }

            return ProviderProfile(
                name: finalName,
                kind: .m3u,
                playlistSource: PlaylistSource(remoteURL: url),
                xmltvSource: parsedGuideSource()
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
                updated.xmltvSource = parsedGuideSource()
                return updated
            }

            return ProviderProfile(
                name: finalName,
                kind: .xtream,
                xmltvSource: parsedGuideSource(),
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
        rebuildItemIndexes()
        lastUpdatedAt = .now
        upsertSavedProfile(
            SavedProfileRecord(
                profile: profile,
                groups: parsed.groups,
                items: items,
                lastUpdatedAt: .now,
                lastOpenedAt: .now,
                lastSelectedGroupID: matchingSavedProfile(
                    kind: profile.kind,
                    remoteURL: profile.playlistSource?.remoteURL,
                    rawText: profile.playlistSource?.rawText,
                    host: profile.xtreamCredentials?.host,
                    username: profile.xtreamCredentials?.username,
                    password: profile.xtreamCredentials?.password
                )?.lastSelectedGroupID,
                lastPlayedItemID: matchingSavedProfile(
                    kind: profile.kind,
                    remoteURL: profile.playlistSource?.remoteURL,
                    rawText: profile.playlistSource?.rawText,
                    host: profile.xtreamCredentials?.host,
                    username: profile.xtreamCredentials?.username,
                    password: profile.xtreamCredentials?.password
                )?.lastPlayedItemID,
                lastPlayedItemTitle: matchingSavedProfile(
                    kind: profile.kind,
                    remoteURL: profile.playlistSource?.remoteURL,
                    rawText: profile.playlistSource?.rawText,
                    host: profile.xtreamCredentials?.host,
                    username: profile.xtreamCredentials?.username,
                    password: profile.xtreamCredentials?.password
                )?.lastPlayedItemTitle
            )
        )
        populateInputs(from: profile)
        persistence.saveActiveProfileID(profile.id)
    }

    private func bindDraftPersistence() {
        Publishers.CombineLatest4($sourceMode, $profileName, $m3uURLString, $guideURLString)
            .combineLatest(Publishers.CombineLatest4($rawM3UText, $xtreamHostString, $xtreamUsername, $xtreamPassword))
            .sink { [weak self] lhs, rhs in
                guard let self else { return }

                let draft = SourceDraft(
                    sourceMode: lhs.0.rawValue,
                    profileName: lhs.1,
                    m3uURLString: lhs.2,
                    guideURLString: lhs.3,
                    rawM3UText: rhs.0,
                    xtreamHostString: rhs.1,
                    xtreamUsername: rhs.2,
                    xtreamPassword: rhs.3
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
            sourceMode = SourceMode(rawValue: draft.sourceMode) ?? .m3u
            profileName = draft.profileName
            m3uURLString = draft.m3uURLString
            guideURLString = draft.guideURLString
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
            sourceMode = .m3u
            m3uURLString = profile.playlistSource?.remoteURL?.absoluteString ?? ""
            guideURLString = profile.xmltvSource?.remoteURL?.absoluteString ?? profile.xmltvSource?.rawText ?? ""
            rawM3UText = profile.playlistSource?.rawText ?? ""
            xtreamHostString = ""
            xtreamUsername = ""
            xtreamPassword = ""

        case .xtream:
            sourceMode = .xtream
            m3uURLString = ""
            guideURLString = profile.xmltvSource?.remoteURL?.absoluteString ?? profile.xmltvSource?.rawText ?? ""
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
        rebuildItemIndexes()
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

    private func rebuildItemIndexes() {
        groupNamesByID = Dictionary(uniqueKeysWithValues: groups.map { ($0.id, $0.name) })
        itemsByGroupID = Dictionary(grouping: items) { $0.groupID ?? "ungrouped" }
        groupCountsByID = itemsByGroupID.mapValues(\.count)
        searchableTextByItemKey = Dictionary(uniqueKeysWithValues: items.map { item in
            let groupName = item.groupID.flatMap { groupNamesByID[$0] } ?? item.groupID ?? ""
            let searchText = normalizedSearchText("\(item.title) \(groupName)")
            return (searchKey(for: item), searchText)
        })
        sortedGroupsByItemCount = groups.sorted { lhs, rhs in
            let lhsCount = groupCountsByID[lhs.id] ?? 0
            let rhsCount = groupCountsByID[rhs.id] ?? 0
            if lhsCount == rhsCount {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lhsCount > rhsCount
        }
    }

    private func searchKey(for item: MediaItem) -> String {
        "\(item.providerID.uuidString)::\(item.id)"
    }

    private func normalizedSearchText(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    private func markLastPlayed(_ item: MediaItem) {
        guard let index = savedProfiles.firstIndex(where: { $0.id == item.providerID }) else {
            return
        }

        savedProfiles[index].lastPlayedItemID = item.id
        savedProfiles[index].lastPlayedItemTitle = item.title
        savedProfiles[index].lastSelectedGroupID = item.groupID
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

    private func parsedGuideSource() -> PlaylistSource? {
        let trimmed = guideURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        guard let url = URL(string: trimmed), ["http", "https"].contains(url.scheme?.lowercased() ?? "") else {
            return nil
        }

        return PlaylistSource(remoteURL: url)
    }

    private func reloadGuideIfAvailable(for profile: ProviderProfile, items: [MediaItem]) async {
        guard let guideSource = profile.xmltvSource else {
            nowNextByProfileID[profile.id] = nil
            guideStatusMessage = nil
            return
        }

        do {
            let parsedGuide = try await guideLoader.load(source: guideSource)
            let matches = epgMatcher.nowNextMap(for: items, epg: parsedGuide)
            nowNextByProfileID[profile.id] = matches
            guideStatusMessage = matches.isEmpty
                ? "Guide loaded but no channels matched yet."
                : "Guide matched \(matches.count) channels."
        } catch {
            nowNextByProfileID[profile.id] = nil
            guideStatusMessage = "Guide unavailable: \(friendlyMessage(for: error))"
        }
    }
}
