import Foundation
import IPTVDomain

public struct ParsedPlaylist: Sendable {
    public var groups: [MediaGroup]
    public var items: [MediaItem]

    public init(groups: [MediaGroup], items: [MediaItem]) {
        self.groups = groups
        self.items = items
    }
}

public enum M3UParserError: Error, Equatable {
    case missingHeader
}

public struct M3UParser: Sendable {
    public init() {}

    public func parse(text: String, providerID: UUID) throws -> ParsedPlaylist {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)

        guard lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) == "#EXTM3U" else {
            throw M3UParserError.missingHeader
        }

        var items: [MediaItem] = []
        var groupsByName: [String: MediaGroup] = [:]
        var pendingMetadata: PendingEntry?
        var order = 0

        for rawLine in lines.dropFirst() {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !line.isEmpty else { continue }

            if line.hasPrefix("#EXTINF:") {
                pendingMetadata = parseMetadata(from: line)
                continue
            }

            if line.hasPrefix("#") {
                continue
            }

            guard let entry = pendingMetadata, let streamURL = URL(string: line) else {
                continue
            }

            let groupName = entry.groupTitle ?? "Ungrouped"
            let groupID = groupIdentifier(for: groupName)

            if groupsByName[groupName] == nil {
                groupsByName[groupName] = MediaGroup(id: groupID, name: groupName, order: order)
                order += 1
            }

            let title = entry.name.isEmpty ? (entry.tvgName ?? "Untitled Channel") : entry.name
            let artwork = ArtworkSet(
                posterURL: entry.logo.flatMap(URL.init(string:)),
                thumbnailURL: entry.logo.flatMap(URL.init(string:))
            )

            let item = MediaItem(
                id: entry.tvgID ?? streamURL.absoluteString,
                providerID: providerID,
                groupID: groupID,
                kind: .live,
                title: title,
                artwork: artwork,
                source: PlaybackSource(
                    url: streamURL,
                    containerHint: containerHint(for: streamURL)
                )
            )
            items.append(item)
            pendingMetadata = nil
        }

        let groups = groupsByName.values.sorted { lhs, rhs in
            lhs.order < rhs.order
        }

        return ParsedPlaylist(groups: groups, items: items)
    }

    private func parseMetadata(from line: String) -> PendingEntry {
        let payload = String(line.dropFirst("#EXTINF:".count))
        let title = payload.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)

        let attributesPart = title.first.map(String.init) ?? ""
        let name = title.count > 1 ? String(title[1]).trimmingCharacters(in: .whitespaces) : ""

        return PendingEntry(
            tvgID: attributeValue(for: "tvg-id", in: attributesPart),
            tvgName: attributeValue(for: "tvg-name", in: attributesPart),
            logo: attributeValue(for: "tvg-logo", in: attributesPart),
            groupTitle: attributeValue(for: "group-title", in: attributesPart),
            name: name
        )
    }

    private func attributeValue(for key: String, in text: String) -> String? {
        let pattern = #"\#(key)="([^"]*)""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let nsrange = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: nsrange),
              let range = Range(match.range(at: 1), in: text)
        else {
            return nil
        }

        return String(text[range])
    }

    private func groupIdentifier(for name: String) -> String {
        name
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private func containerHint(for url: URL) -> String? {
        if !url.pathExtension.isEmpty {
            return url.pathExtension.lowercased()
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let queryItems = components.queryItems ?? []
        let queryBackedKeys = ["output", "container", "extension", "format", "type"]

        for key in queryBackedKeys {
            if let value = queryItems.first(where: { $0.name.caseInsensitiveCompare(key) == .orderedSame })?.value?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased(),
               !value.isEmpty
            {
                return value
            }
        }

        return nil
    }
}

private struct PendingEntry {
    var tvgID: String?
    var tvgName: String?
    var logo: String?
    var groupTitle: String?
    var name: String
}
