import Foundation
import IPTVDomain

struct SavedProfileRecord: Identifiable, Codable, Equatable {
    var profile: ProviderProfile
    var groups: [MediaGroup]
    var items: [MediaItem]
    var lastUpdatedAt: Date?
    var lastOpenedAt: Date?

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
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private enum Key {
        static let savedProfiles = "app.savedProfiles"
        static let sourceDraft = "app.sourceDraft"
        static let activeProfileID = "app.activeProfileID"
        static let favorites = "app.favorites"
        static let recents = "app.recents"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder.outputFormatting = [.sortedKeys]
    }

    func loadProfiles() -> [SavedProfileRecord] {
        guard let data = defaults.data(forKey: Key.savedProfiles),
              let records = try? decoder.decode([SavedProfileRecord].self, from: data) else {
            return []
        }

        return records.sorted { lhs, rhs in
            let lhsDate = lhs.lastOpenedAt ?? lhs.lastUpdatedAt ?? lhs.profile.createdAt
            let rhsDate = rhs.lastOpenedAt ?? rhs.lastUpdatedAt ?? rhs.profile.createdAt
            return lhsDate > rhsDate
        }
    }

    func saveProfiles(_ records: [SavedProfileRecord]) {
        guard let data = try? encoder.encode(records) else {
            return
        }
        defaults.set(data, forKey: Key.savedProfiles)
    }

    func loadDraft() -> SourceDraft? {
        guard let data = defaults.data(forKey: Key.sourceDraft),
              let draft = try? decoder.decode(SourceDraft.self, from: data) else {
            return nil
        }
        return draft
    }

    func saveDraft(_ draft: SourceDraft) {
        guard let data = try? encoder.encode(draft) else {
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
}
