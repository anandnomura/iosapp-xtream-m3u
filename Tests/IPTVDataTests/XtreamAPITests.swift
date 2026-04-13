import Foundation
import XCTest
import IPTVDomain
@testable import IPTVData

final class XtreamAPITests: XCTestCase {
    func testXtreamBuildsExpectedLiveCategoryURL() {
        let api = XtreamAPI(
            credentials: XtreamCredentials(
                host: URL(string: "https://provider.example.com")!,
                username: "alice",
                password: "secret"
            )
        )

        XCTAssertEqual(
            api.liveCategoriesURL().absoluteString,
            "https://provider.example.com/player_api.php?username=alice&password=secret&action=get_live_categories"
        )
    }

    func testXtreamBuildsExpectedPlaybackURL() {
        let api = XtreamAPI(
            credentials: XtreamCredentials(
                host: URL(string: "https://provider.example.com")!,
                username: "alice",
                password: "secret"
            )
        )

        XCTAssertEqual(
            api.livePlaybackURL(streamID: "42").absoluteString,
            "https://provider.example.com/live/alice/secret/42.m3u8"
        )
        XCTAssertEqual(
            api.vodPlaybackURL(streamID: "88", fileExtension: "mkv").absoluteString,
            "https://provider.example.com/movie/alice/secret/88.mkv"
        )
    }

    func testXtreamLoaderMapsLiveCategoriesAndStreams() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]

        let session = URLSession(configuration: configuration)
        let loader = XtreamLivePlaylistLoader(session: session)
        let credentials = XtreamCredentials(
            host: URL(string: "https://provider.example.com")!,
            username: "alice",
            password: "secret"
        )

        MockURLProtocol.handlers = [
            "https://provider.example.com/player_api.php?username=alice&password=secret&action=get_live_categories": (
                200,
                """
                [
                  { "category_id": "10", "category_name": "News", "parent_id": 1 },
                  { "category_id": "20", "category_name": "Sports", "parent_id": 2 }
                ]
                """
            ),
            "https://provider.example.com/player_api.php?username=alice&password=secret&action=get_live_streams": (
                200,
                """
                [
                  {
                    "stream_id": 42,
                    "name": "BBC One HD",
                    "category_id": "10",
                    "stream_icon": "https://img.example.com/bbc.png",
                    "epg_channel_id": "bbc1.uk",
                    "container_extension": "m3u8"
                  }
                ]
                """
            )
        ]

        let parsed = try await loader.load(credentials: credentials, providerID: UUID())

        XCTAssertEqual(parsed.groups.map(\.name), ["News", "Sports"])
        XCTAssertEqual(parsed.items.count, 1)
        XCTAssertEqual(parsed.items[0].title, "BBC One HD")
        XCTAssertEqual(parsed.items[0].groupID, "10")
        XCTAssertEqual(parsed.items[0].source?.url.absoluteString, "https://provider.example.com/live/alice/secret/42.m3u8")
    }
}

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    static var handlers: [String: (statusCode: Int, body: String)] = [:]

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url?.absoluteString,
              let handler = Self.handlers[url]
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: handler.statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(handler.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
