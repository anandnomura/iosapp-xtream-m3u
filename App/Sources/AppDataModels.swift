import Foundation
import SwiftData

@Model
final class ProfileStateRecord {
    @Attribute(.unique) var profileID: String
    var profileName: String
    var providerKind: String
    var lastSelectedGroupID: String?
    var lastPlayedItemID: String?
    var lastPlayedItemTitle: String?
    var lastRefreshedAt: Date?

    init(
        profileID: String,
        profileName: String,
        providerKind: String,
        lastSelectedGroupID: String? = nil,
        lastPlayedItemID: String? = nil,
        lastPlayedItemTitle: String? = nil,
        lastRefreshedAt: Date? = nil
    ) {
        self.profileID = profileID
        self.profileName = profileName
        self.providerKind = providerKind
        self.lastSelectedGroupID = lastSelectedGroupID
        self.lastPlayedItemID = lastPlayedItemID
        self.lastPlayedItemTitle = lastPlayedItemTitle
        self.lastRefreshedAt = lastRefreshedAt
    }
}

@Model
final class FavoriteChannelRecord {
    @Attribute(.unique) var compositeID: String
    var providerID: String
    var itemID: String
    var title: String
    var groupID: String?
    var savedAt: Date

    init(
        compositeID: String,
        providerID: String,
        itemID: String,
        title: String,
        groupID: String? = nil,
        savedAt: Date = .now
    ) {
        self.compositeID = compositeID
        self.providerID = providerID
        self.itemID = itemID
        self.title = title
        self.groupID = groupID
        self.savedAt = savedAt
    }
}

@Model
final class RecentChannelRecord {
    @Attribute(.unique) var compositeID: String
    var providerID: String
    var itemID: String
    var title: String
    var groupID: String?
    var openedAt: Date

    init(
        compositeID: String,
        providerID: String,
        itemID: String,
        title: String,
        groupID: String? = nil,
        openedAt: Date = .now
    ) {
        self.compositeID = compositeID
        self.providerID = providerID
        self.itemID = itemID
        self.title = title
        self.groupID = groupID
        self.openedAt = openedAt
    }
}
