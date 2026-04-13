import Foundation
import XCTest
import IPTVDomain
@testable import IPTVData

final class M3UParserTests: XCTestCase {
    func testParserBuildsGroupsAndItems() throws {
        let parser = M3UParser()
        let providerID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        let playlist = """
        #EXTM3U
        #EXTINF:-1 tvg-id="bbc1" tvg-name="BBC One" tvg-logo="https://img.example.com/bbc.png" group-title="News",BBC One HD
        https://stream.example.com/live/bbc1.m3u8
        #EXTINF:-1 group-title="Sports",ESPN
        https://stream.example.com/live/espn.ts
        """

        let parsed = try parser.parse(text: playlist, providerID: providerID)

        XCTAssertEqual(parsed.groups.map(\.name), ["News", "Sports"])
        XCTAssertEqual(parsed.items.count, 2)
        XCTAssertEqual(parsed.items[0].title, "BBC One HD")
        XCTAssertEqual(parsed.items[0].groupID, "news")
        XCTAssertEqual(parsed.items[0].source?.containerHint, "m3u8")
        XCTAssertEqual(parsed.items[1].source?.containerHint, "ts")
    }

    func testParserRejectsPlaylistWithoutHeader() {
        let parser = M3UParser()

        XCTAssertThrowsError(try parser.parse(text: "#EXTINF:-1,Channel", providerID: UUID())) { error in
            XCTAssertEqual(error as? M3UParserError, .missingHeader)
        }
    }

    func testParserInfersContainerFromQueryString() throws {
        let parser = M3UParser()
        let providerID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let playlist = """
        #EXTM3U
        #EXTINF:-1 group-title="Live",Arena Sport
        http://example.com/live/user/pass/12345?output=ts
        """

        let parsed = try parser.parse(text: playlist, providerID: providerID)

        XCTAssertEqual(parsed.items.count, 1)
        XCTAssertEqual(parsed.items[0].source?.containerHint, "ts")
    }

    func testParserAcceptsBomAndLeadingBlankLines() throws {
        let parser = M3UParser()
        let providerID = UUID(uuidString: "99999999-8888-7777-6666-555555555555")!
        let playlist = """
        \u{FEFF}

        #EXTM3U
        #EXTINF:-1 group-title="Live",Channel One
        http://example.com/live/1.ts
        """

        let parsed = try parser.parse(text: playlist, providerID: providerID)

        XCTAssertEqual(parsed.items.count, 1)
        XCTAssertEqual(parsed.groups.first?.name, "Live")
    }
}
