import Foundation
import IPTVDomain

public struct EPGMatcher: Sendable {
    public init() {}

    public func nowNextMap(
        for items: [MediaItem],
        epg: ParsedEPG,
        at date: Date = .now
    ) -> [String: ChannelNowNext] {
        let programmesByChannel = Dictionary(grouping: epg.programmes) { $0.channelID }
        let channelsByID = Dictionary(uniqueKeysWithValues: epg.channels.map { ($0.id, $0) })

        var matches: [String: ChannelNowNext] = [:]

        for item in items {
            guard let channelID = bestChannelID(for: item, channelsByID: channelsByID) else {
                continue
            }

            let ordered = (programmesByChannel[channelID] ?? []).sorted { $0.startDate < $1.startDate }
            let current = ordered.first(where: { $0.startDate <= date && $0.endDate > date })
            let next: EPGProgramme?

            if let current {
                next = ordered.first(where: { $0.startDate >= current.endDate })
            } else {
                next = ordered.first(where: { $0.startDate > date })
            }

            matches[item.id] = ChannelNowNext(
                mediaItemID: item.id,
                channelID: channelID,
                current: current,
                next: next
            )
        }

        return matches
    }

    private func bestChannelID(for item: MediaItem, channelsByID: [String: EPGChannel]) -> String? {
        if channelsByID[item.id] != nil {
            return item.id
        }

        let normalizedItemID = normalized(item.id)
        if let channel = channelsByID.values.first(where: { normalized($0.id) == normalizedItemID }) {
            return channel.id
        }

        let normalizedTitle = normalized(item.title)
        if let channel = channelsByID.values.first(where: { normalized($0.displayName) == normalizedTitle }) {
            return channel.id
        }

        return nil
    }

    private func normalized(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "[^a-z0-9]+", with: "", options: .regularExpression)
            .lowercased()
    }
}
