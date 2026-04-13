import Foundation
import XCTest
import IPTVDomain
@testable import IPTVData

final class PlaylistLoaderTests: XCTestCase {
    func testM3ULoaderUsesRawTextWithoutNetworking() async throws {
        let loader = M3UPlaylistLoader(session: .shared, parser: M3UParser())
        let source = PlaylistSource(
            rawText: """
            #EXTM3U
            #EXTINF:-1 group-title="News",News One
            https://stream.example.com/news.m3u8
            """
        )

        let parsed = try await loader.load(source: source, providerID: UUID())

        XCTAssertEqual(parsed.groups.map(\.name), ["News"])
        XCTAssertEqual(parsed.items.map(\.title), ["News One"])
    }

    func testM3ULoaderFetchesRemoteText() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [PlaylistLoaderMockURLProtocol.self]

        let session = URLSession(configuration: configuration)
        let loader = M3UPlaylistLoader(session: session, parser: M3UParser())
        let source = PlaylistSource(remoteURL: URL(string: "https://provider.example.com/list.m3u")!)

        PlaylistLoaderMockURLProtocol.handlers = [
            "https://provider.example.com/list.m3u": (
                200,
                Data(
                    """
                #EXTM3U
                #EXTINF:-1 group-title="Sports",Sports One
                https://stream.example.com/sports.m3u8
                """.utf8
                )
            )
        ]

        let parsed = try await loader.load(source: source, providerID: UUID())

        XCTAssertEqual(parsed.groups.map(\.name), ["Sports"])
        XCTAssertEqual(parsed.items.map(\.title), ["Sports One"])
    }

    func testM3ULoaderAcceptsUtf16PlaylistAndLeadingPadding() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [PlaylistLoaderMockURLProtocol.self]

        let session = URLSession(configuration: configuration)
        let loader = M3UPlaylistLoader(session: session, parser: M3UParser())
        let source = PlaylistSource(remoteURL: URL(string: "https://provider.example.com/list-utf16.m3u")!)

        let utf16Body = """
        \u{FEFF}

        #EXTM3U
        #EXTINF:-1 group-title="Movies",Movie One
        http://stream.example.com/movie.ts
        """

        PlaylistLoaderMockURLProtocol.handlers = [
            "https://provider.example.com/list-utf16.m3u": (
                200,
                utf16Body.data(using: .utf16)!
            )
        ]

        let parsed = try await loader.load(source: source, providerID: UUID())

        XCTAssertEqual(parsed.groups.map(\.name), ["Movies"])
        XCTAssertEqual(parsed.items.map(\.title), ["Movie One"])
    }
}

private final class PlaylistLoaderMockURLProtocol: URLProtocol, @unchecked Sendable {
    static var handlers: [String: (statusCode: Int, body: Data)] = [:]

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
            headerFields: ["Content-Type": "application/x-mpegURL"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: handler.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
