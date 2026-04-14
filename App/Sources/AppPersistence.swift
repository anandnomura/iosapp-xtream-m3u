import Foundation
import IPTVDomain

struct SavedProfileRecord: Identifiable, Codable, Equatable {
    var profile: ProviderProfile
    var groups: [MediaGroup]
    var items: [MediaItem]
    var lastUpdatedAt: Date?
    var lastOpenedAt: Date?
    var lastSelectedGroupID: String?
    var lastPlayedItemID: String?
    var lastPlayedItemTitle: String?

    var id: UUID { profile.id }
}

struct SourceDraft: Codable, Equatable {
    var sourceMode: String
    var profileName: String
    var m3uURLString: String
    var rawM3UText: String
    var xtreamHostString: String
    var xtreamUsername: String
    var xtreamPassword: String
}

@MainActor
final class AppPersistence {
    static let shared = AppPersistence()

    private let defaults: UserDefaults
    private let keychain: KeychainStore
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private enum Key {
        static let savedProfiles = "app.savedProfiles"
        static let sourceDraft = "app.sourceDraft"
        static let activeProfileID = "app.activeProfileID"
        static let favorites = "app.favorites"
        static let recents = "app.recents"
        static let xtreamDraftPasswordService = "app.xtream.draft.password"
        static let xtreamProfilePasswordServicePrefix = "app.xtream.profile.password"
    }

    init(defaults: UserDefaults = .standard, keychain: KeychainStore = .shared) {
        self.defaults = defaults
        self.keychain = keychain
        encoder.outputFormatting = [.sortedKeys]
    }

    func loadProfiles() -> [SavedProfileRecord] {
        guard let data = defaults.data(forKey: Key.savedProfiles),
              let records = try? decoder.decode([SavedProfileRecord].self, from: data) else {
            return []
        }

        let hydrated = records.map(hydrateProfileSecrets)

        return hydrated.sorted { lhs, rhs in
            let lhsDate = lhs.lastOpenedAt ?? lhs.lastUpdatedAt ?? lhs.profile.createdAt
            let rhsDate = rhs.lastOpenedAt ?? rhs.lastUpdatedAt ?? rhs.profile.createdAt
            return lhsDate > rhsDate
        }
    }

    func saveProfiles(_ records: [SavedProfileRecord]) {
        let sanitized = records.map(storeProfileSecrets)
        guard let data = try? encoder.encode(sanitized) else {
            return
        }
        defaults.set(data, forKey: Key.savedProfiles)
    }

    func loadDraft() -> SourceDraft? {
        guard let data = defaults.data(forKey: Key.sourceDraft),
              let draft = try? decoder.decode(SourceDraft.self, from: data) else {
            return nil
        }

        return hydrateDraftSecret(draft)
    }

    func saveDraft(_ draft: SourceDraft) {
        let sanitized = storeDraftSecret(draft)
        guard let data = try? encoder.encode(sanitized) else {
            return
        }
        defaults.set(data, forKey: Key.sourceDraft)
    }

    func loadActiveProfileID() -> UUID? {
        guard let rawValue = defaults.string(forKey: Key.activeProfileID) else {
            return nil
        }

        return UUID(uuidString: rawValue)
    }

    func saveActiveProfileID(_ id: UUID?) {
        defaults.set(id?.uuidString, forKey: Key.activeProfileID)
    }

    func loadFavorites() -> [MediaItem] {
        guard let data = defaults.data(forKey: Key.favorites),
              let items = try? decoder.decode([MediaItem].self, from: data) else {
            return []
        }
        return items
    }

    func saveFavorites(_ items: [MediaItem]) {
        guard let data = try? encoder.encode(items) else {
            return
        }
        defaults.set(data, forKey: Key.favorites)
    }

    func loadRecents() -> [MediaItem] {
        guard let data = defaults.data(forKey: Key.recents),
              let items = try? decoder.decode([MediaItem].self, from: data) else {
            return []
        }
        return items
    }

    func saveRecents(_ items: [MediaItem]) {
        guard let data = try? encoder.encode(items) else {
            return
        }
        defaults.set(data, forKey: Key.recents)
    }

    func deleteProfileSecrets(ids: [UUID]) {
        for id in ids {
            keychain.deletePassword(service: profilePasswordService(for: id), account: "xtreamPassword")
        }
    }

    private func hydrateDraftSecret(_ draft: SourceDraft) -> SourceDraft {
        var hydrated = draft
        hydrated.xtreamPassword = keychain.loadPassword(service: Key.xtreamDraftPasswordService, account: "xtreamPassword") ?? draft.xtreamPassword
        return hydrated
    }

    private func storeDraftSecret(_ draft: SourceDraft) -> SourceDraft {
        var sanitized = draft

        if draft.xtreamPassword.isEmpty {
            keychain.deletePassword(service: Key.xtreamDraftPasswordService, account: "xtreamPassword")
        } else {
            keychain.savePassword(draft.xtreamPassword, service: Key.xtreamDraftPasswordService, account: "xtreamPassword")
            sanitized.xtreamPassword = ""
        }

        return sanitized
    }

    private func hydrateProfileSecrets(_ record: SavedProfileRecord) -> SavedProfileRecord {
        guard record.profile.kind == .xtream else {
            return record
        }

        var hydrated = record
        if var credentials = hydrated.profile.xtreamCredentials {
            let service = profilePasswordService(for: hydrated.id)
            if let keychainPassword = keychain.loadPassword(service: service, account: "xtreamPassword") {
                credentials.password = keychainPassword
            } else if !credentials.password.isEmpty {
                keychain.savePassword(credentials.password, service: service, account: "xtreamPassword")
            }
            hydrated.profile.xtreamCredentials = credentials
        }
        return hydrated
    }

    private func storeProfileSecrets(_ record: SavedProfileRecord) -> SavedProfileRecord {
        guard record.profile.kind == .xtream else {
            return record
        }

        var sanitized = record
        if var credentials = sanitized.profile.xtreamCredentials {
            let service = profilePasswordService(for: sanitized.id)
            if credentials.password.isEmpty {
                keychain.deletePassword(service: service, account: "xtreamPassword")
            } else {
                keychain.savePassword(credentials.password, service: service, account: "xtreamPassword")
                credentials.password = ""
            }
            sanitized.profile.xtreamCredentials = credentials
        }
        return sanitized
    }

    private func profilePasswordService(for id: UUID) -> String {
        "\(Key.xtreamProfilePasswordServicePrefix).\(id.uuidString)"
    }
}
