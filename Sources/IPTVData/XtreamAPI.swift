import Foundation
import IPTVDomain

public struct XtreamAPI: Sendable {
    public let credentials: XtreamCredentials

    public init(credentials: XtreamCredentials) {
        self.credentials = credentials
    }

    public var playerAPI: URL {
        credentials.host
            .appending(path: "player_api.php")
            .appending(queryItems: [
                URLQueryItem(name: "username", value: credentials.username),
                URLQueryItem(name: "password", value: credentials.password)
            ])
    }

    public func liveCategoriesURL() -> URL {
        playerAPI.appending(queryItems: [
            URLQueryItem(name: "action", value: "get_live_categories")
        ])
    }

    public func liveStreamsURL(categoryID: String? = nil) -> URL {
        var items = [URLQueryItem(name: "action", value: "get_live_streams")]
        if let categoryID {
            items.append(URLQueryItem(name: "category_id", value: categoryID))
        }
        return playerAPI.appending(queryItems: items)
    }

    public func vodCategoriesURL() -> URL {
        playerAPI.appending(queryItems: [
            URLQueryItem(name: "action", value: "get_vod_categories")
        ])
    }

    public func vodStreamsURL(categoryID: String? = nil) -> URL {
        var items = [URLQueryItem(name: "action", value: "get_vod_streams")]
        if let categoryID {
            items.append(URLQueryItem(name: "category_id", value: categoryID))
        }
        return playerAPI.appending(queryItems: items)
    }

    public func seriesCategoriesURL() -> URL {
        playerAPI.appending(queryItems: [
            URLQueryItem(name: "action", value: "get_series_categories")
        ])
    }

    public func seriesURL(categoryID: String? = nil) -> URL {
        var items = [URLQueryItem(name: "action", value: "get_series")]
        if let categoryID {
            items.append(URLQueryItem(name: "category_id", value: categoryID))
        }
        return playerAPI.appending(queryItems: items)
    }

    public func seriesInfoURL(seriesID: String) -> URL {
        playerAPI.appending(queryItems: [
            URLQueryItem(name: "action", value: "get_series_info"),
            URLQueryItem(name: "series_id", value: seriesID)
        ])
    }

    public func livePlaybackURL(streamID: String, fileExtension: String = "m3u8") -> URL {
        credentials.host
            .appending(path: "live")
            .appending(path: credentials.username)
            .appending(path: credentials.password)
            .appending(path: "\(streamID).\(fileExtension)")
    }

    public func vodPlaybackURL(streamID: String, fileExtension: String = "mp4") -> URL {
        credentials.host
            .appending(path: "movie")
            .appending(path: credentials.username)
            .appending(path: credentials.password)
            .appending(path: "\(streamID).\(fileExtension)")
    }

    public func seriesPlaybackURL(streamID: String, fileExtension: String = "mp4") -> URL {
        credentials.host
            .appending(path: "series")
            .appending(path: credentials.username)
            .appending(path: credentials.password)
            .appending(path: "\(streamID).\(fileExtension)")
    }
}

private extension URL {
    func appending(queryItems: [URLQueryItem]) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }

        var updated = components.queryItems ?? []
        updated.append(contentsOf: queryItems)
        components.queryItems = updated
        return components.url ?? self
    }
}
