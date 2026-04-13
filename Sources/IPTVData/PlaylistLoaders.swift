import Foundation
import IPTVDomain

public enum PlaylistLoaderError: Error, Equatable, LocalizedError {
    case missingSource
    case invalidURL
    case invalidResponse
    case emptyCredentials

    public var errorDescription: String? {
        switch self {
        case .missingSource:
            return "A playlist source is required."
        case .invalidURL:
            return "The URL is invalid."
        case .invalidResponse:
            return "The server response could not be read."
        case .emptyCredentials:
            return "Host, username, and password are required."
        }
    }
}

public struct M3UPlaylistLoader: Sendable {
    public var session: URLSession
    public var parser: M3UParser

    public init(session: URLSession = .shared, parser: M3UParser = M3UParser()) {
        self.session = session
        self.parser = parser
    }

    public func load(source: PlaylistSource, providerID: UUID) async throws -> ParsedPlaylist {
        if let rawText = source.rawText?.trimmingCharacters(in: .whitespacesAndNewlines), !rawText.isEmpty {
            return try parser.parse(text: rawText, providerID: providerID)
        }

        guard let remoteURL = source.remoteURL else {
            throw PlaylistLoaderError.missingSource
        }

        let (data, response) = try await session.data(from: remoteURL)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw PlaylistLoaderError.invalidResponse
        }

        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            throw PlaylistLoaderError.invalidResponse
        }

        return try parser.parse(text: text, providerID: providerID)
    }
}

public struct XtreamLivePlaylistLoader: Sendable {
    public var session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func load(credentials: XtreamCredentials, providerID: UUID) async throws -> ParsedPlaylist {
        guard !credentials.username.isEmpty, !credentials.password.isEmpty else {
            throw PlaylistLoaderError.emptyCredentials
        }

        let api = XtreamAPI(credentials: credentials)
        async let categoriesTask = fetch([XtreamCategory].self, from: api.liveCategoriesURL())
        async let streamsTask = fetch([XtreamLiveStream].self, from: api.liveStreamsURL())

        let (categories, streams) = try await (categoriesTask, streamsTask)

        var groupsByID: [String: MediaGroup] = [:]
        for (index, category) in categories.enumerated() {
            groupsByID[category.id] = MediaGroup(id: category.id, name: category.name, order: index)
        }

        var dynamicOrder = categories.count
        var items: [MediaItem] = []

        for stream in streams {
            let groupID = stream.categoryID ?? "ungrouped"

            if groupsByID[groupID] == nil {
                groupsByID[groupID] = MediaGroup(
                    id: groupID,
                    name: stream.categoryName ?? "Ungrouped",
                    order: dynamicOrder
                )
                dynamicOrder += 1
            }

            let playbackURL = api.livePlaybackURL(
                streamID: stream.streamID,
                fileExtension: stream.containerExtension ?? "m3u8"
            )

            items.append(
                MediaItem(
                    id: stream.streamID,
                    providerID: providerID,
                    groupID: groupID,
                    kind: .live,
                    title: stream.name,
                    synopsis: stream.epgChannelID,
                    artwork: ArtworkSet(
                        posterURL: stream.streamIcon,
                        thumbnailURL: stream.streamIcon
                    ),
                    source: PlaybackSource(
                        url: playbackURL,
                        containerHint: stream.containerExtension
                    )
                )
            )
        }

        let groups = groupsByID.values.sorted { lhs, rhs in
            lhs.order < rhs.order
        }

        return ParsedPlaylist(groups: groups, items: items)
    }

    private func fetch<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw PlaylistLoaderError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
}

private struct XtreamCategory: Decodable {
    let id: String
    let name: String

    private enum CodingKeys: String, CodingKey {
        case id = "category_id"
        case name = "category_name"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeFlexibleString(forKey: .id)
        name = try container.decode(String.self, forKey: .name)
    }
}

private struct XtreamLiveStream: Decodable {
    let streamID: String
    let name: String
    let categoryID: String?
    let categoryName: String?
    let streamIcon: URL?
    let epgChannelID: String?
    let containerExtension: String?

    private enum CodingKeys: String, CodingKey {
        case streamID = "stream_id"
        case name
        case categoryID = "category_id"
        case categoryName = "category_name"
        case streamIcon = "stream_icon"
        case epgChannelID = "epg_channel_id"
        case containerExtension = "container_extension"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        streamID = try container.decodeFlexibleString(forKey: .streamID)
        name = try container.decode(String.self, forKey: .name)
        categoryID = try container.decodeFlexibleStringIfPresent(forKey: .categoryID)
        categoryName = try container.decodeIfPresent(String.self, forKey: .categoryName)
        streamIcon = try container.decodeURLIfPresent(forKey: .streamIcon)
        epgChannelID = try container.decodeIfPresent(String.self, forKey: .epgChannelID)
        containerExtension = try container.decodeIfPresent(String.self, forKey: .containerExtension)
    }
}

private extension KeyedDecodingContainer {
    func decodeFlexibleString(forKey key: Key) throws -> String {
        if let stringValue = try? decode(String.self, forKey: key) {
            return stringValue
        }

        if let intValue = try? decode(Int.self, forKey: key) {
            return String(intValue)
        }

        if let doubleValue = try? decode(Double.self, forKey: key) {
            return String(Int(doubleValue))
        }

        throw DecodingError.typeMismatch(
            String.self,
            DecodingError.Context(codingPath: codingPath + [key], debugDescription: "Expected a string-compatible value.")
        )
    }

    func decodeFlexibleStringIfPresent(forKey key: Key) throws -> String? {
        if let stringValue = try? decodeIfPresent(String.self, forKey: key) {
            return stringValue
        }

        if let intValue = try? decodeIfPresent(Int.self, forKey: key) {
            return intValue.map(String.init)
        }

        if let doubleValue = try? decodeIfPresent(Double.self, forKey: key) {
            return doubleValue.map { String(Int($0)) }
        }

        return nil
    }

    func decodeURLIfPresent(forKey key: Key) throws -> URL? {
        guard let rawValue = try decodeIfPresent(String.self, forKey: key),
              !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        return URL(string: rawValue)
    }
}
