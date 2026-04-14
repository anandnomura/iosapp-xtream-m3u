import Foundation

public enum ProviderKind: String, Codable, Sendable {
    case m3u
    case xtream
}

public struct XtreamCredentials: Codable, Equatable, Hashable, Sendable {
    public var host: URL
    public var username: String
    public var password: String

    public init(host: URL, username: String, password: String) {
        self.host = host
        self.username = username
        self.password = password
    }
}

public struct PlaylistSource: Codable, Equatable, Hashable, Sendable {
    public var remoteURL: URL?
    public var rawText: String?

    public init(remoteURL: URL? = nil, rawText: String? = nil) {
        self.remoteURL = remoteURL
        self.rawText = rawText
    }
}

public struct ProviderProfile: Identifiable, Codable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var kind: ProviderKind
    public var playlistSource: PlaylistSource?
    public var xtreamCredentials: XtreamCredentials?
    public var isEnabled: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        kind: ProviderKind,
        playlistSource: PlaylistSource? = nil,
        xtreamCredentials: XtreamCredentials? = nil,
        isEnabled: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.playlistSource = playlistSource
        self.xtreamCredentials = xtreamCredentials
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }
}

public enum MediaKind: String, Codable, Sendable {
    case live
    case movie
    case series
    case episode
}

public struct MediaGroup: Identifiable, Codable, Equatable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var order: Int

    public init(id: String, name: String, order: Int = 0) {
        self.id = id
        self.name = name
        self.order = order
    }
}

public struct ArtworkSet: Codable, Equatable, Hashable, Sendable {
    public var posterURL: URL?
    public var thumbnailURL: URL?
    public var backgroundURL: URL?

    public init(posterURL: URL? = nil, thumbnailURL: URL? = nil, backgroundURL: URL? = nil) {
        self.posterURL = posterURL
        self.thumbnailURL = thumbnailURL
        self.backgroundURL = backgroundURL
    }
}

public struct PlaybackSource: Codable, Equatable, Hashable, Sendable {
    public var url: URL
    public var containerHint: String?
    public var headers: [String: String]

    public init(url: URL, containerHint: String? = nil, headers: [String: String] = [:]) {
        self.url = url
        self.containerHint = containerHint
        self.headers = headers
    }
}

public struct MediaItem: Identifiable, Codable, Equatable, Hashable, Sendable {
    public var id: String
    public var providerID: UUID
    public var groupID: String?
    public var kind: MediaKind
    public var title: String
    public var synopsis: String?
    public var artwork: ArtworkSet
    public var source: PlaybackSource?
    public var isFavorite: Bool

    public init(
        id: String,
        providerID: UUID,
        groupID: String? = nil,
        kind: MediaKind,
        title: String,
        synopsis: String? = nil,
        artwork: ArtworkSet = ArtworkSet(),
        source: PlaybackSource? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.providerID = providerID
        self.groupID = groupID
        self.kind = kind
        self.title = title
        self.synopsis = synopsis
        self.artwork = artwork
        self.source = source
        self.isFavorite = isFavorite
    }
}

public struct Season: Identifiable, Codable, Equatable, Hashable, Sendable {
    public var id: String
    public var number: Int
    public var title: String
    public var episodes: [Episode]

    public init(id: String, number: Int, title: String, episodes: [Episode] = []) {
        self.id = id
        self.number = number
        self.title = title
        self.episodes = episodes
    }
}

public struct Episode: Identifiable, Codable, Equatable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var synopsis: String?
    public var seasonNumber: Int
    public var episodeNumber: Int
    public var source: PlaybackSource?

    public init(
        id: String,
        title: String,
        synopsis: String? = nil,
        seasonNumber: Int,
        episodeNumber: Int,
        source: PlaybackSource? = nil
    ) {
        self.id = id
        self.title = title
        self.synopsis = synopsis
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.source = source
    }
}

public struct RecentPlayback: Identifiable, Codable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var mediaID: String
    public var providerID: UUID
    public var lastPositionInSeconds: Int
    public var watchedAt: Date

    public init(
        id: UUID = UUID(),
        mediaID: String,
        providerID: UUID,
        lastPositionInSeconds: Int,
        watchedAt: Date = .now
    ) {
        self.id = id
        self.mediaID = mediaID
        self.providerID = providerID
        self.lastPositionInSeconds = lastPositionInSeconds
        self.watchedAt = watchedAt
    }
}

public struct EPGChannel: Identifiable, Codable, Equatable, Hashable, Sendable {
    public var id: String
    public var displayName: String

    public init(id: String, displayName: String) {
        self.id = id
        self.displayName = displayName
    }
}

public struct EPGProgramme: Identifiable, Codable, Equatable, Hashable, Sendable {
    public var id: String
    public var channelID: String
    public var title: String
    public var subtitle: String?
    public var summary: String?
    public var startDate: Date
    public var endDate: Date

    public init(
        id: String,
        channelID: String,
        title: String,
        subtitle: String? = nil,
        summary: String? = nil,
        startDate: Date,
        endDate: Date
    ) {
        self.id = id
        self.channelID = channelID
        self.title = title
        self.subtitle = subtitle
        self.summary = summary
        self.startDate = startDate
        self.endDate = endDate
    }
}

public struct ParsedEPG: Codable, Equatable, Hashable, Sendable {
    public var channels: [EPGChannel]
    public var programmes: [EPGProgramme]

    public init(channels: [EPGChannel], programmes: [EPGProgramme]) {
        self.channels = channels
        self.programmes = programmes
    }
}
