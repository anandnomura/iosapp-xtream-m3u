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
}
