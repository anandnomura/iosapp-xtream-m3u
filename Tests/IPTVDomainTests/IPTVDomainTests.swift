import XCTest
@testable import IPTVDomain

final class IPTVDomainTests: XCTestCase {
    func testProviderProfileCanRepresentXtreamCredentials() {
        let profile = ProviderProfile(
            name: "Demo",
            kind: .xtream,
            xtreamCredentials: XtreamCredentials(
                host: URL(string: "https://example.com")!,
                username: "user",
                password: "pass"
            )
        )

        XCTAssertEqual(profile.kind, .xtream)
        XCTAssertEqual(profile.xtreamCredentials?.username, "user")
    }

    func testMediaItemCanRepresentFavoriteLiveChannel() {
        let providerID = UUID()
        let item = MediaItem(
            id: "stream-1",
            providerID: providerID,
            groupID: "sports",
            kind: .live,
            title: "Sports HD",
            source: PlaybackSource(url: URL(string: "https://example.com/live.m3u8")!),
            isFavorite: true
        )

        XCTAssertEqual(item.kind, .live)
        XCTAssertTrue(item.isFavorite)
        XCTAssertEqual(item.groupID, "sports")
    }
}
