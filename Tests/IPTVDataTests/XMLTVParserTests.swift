import Foundation
import XCTest
@testable import IPTVData

final class XMLTVParserTests: XCTestCase {
    func testParserBuildsChannelsAndProgrammes() throws {
        let parser = XMLTVParser()
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <tv>
          <channel id="bbc1.uk">
            <display-name>BBC One</display-name>
          </channel>
          <channel id="espn.us">
            <display-name>ESPN</display-name>
          </channel>
          <programme start="20260414060000 +0000" stop="20260414070000 +0000" channel="bbc1.uk">
            <title>Breakfast</title>
            <sub-title>Morning Headlines</sub-title>
            <desc>Daily news bulletin.</desc>
          </programme>
          <programme start="20260414070000 +0000" stop="20260414090000 +0000" channel="espn.us">
            <title>SportsCenter</title>
          </programme>
        </tv>
        """

        let parsed = try parser.parse(data: Data(xml.utf8))

        XCTAssertEqual(parsed.channels.count, 2)
        XCTAssertEqual(parsed.channels.map(\.displayName), ["BBC One", "ESPN"])
        XCTAssertEqual(parsed.programmes.count, 2)
        XCTAssertEqual(parsed.programmes[0].channelID, "bbc1.uk")
        XCTAssertEqual(parsed.programmes[0].title, "Breakfast")
        XCTAssertEqual(parsed.programmes[0].subtitle, "Morning Headlines")
        XCTAssertEqual(parsed.programmes[0].summary, "Daily news bulletin.")
    }

    func testParserRejectsInvalidProgrammeDate() {
        let parser = XMLTVParser()
        let xml = """
        <tv>
          <channel id="bbc1.uk">
            <display-name>BBC One</display-name>
          </channel>
          <programme start="bad-date" stop="20260414070000 +0000" channel="bbc1.uk">
            <title>Breakfast</title>
          </programme>
        </tv>
        """

        XCTAssertThrowsError(try parser.parse(data: Data(xml.utf8))) { error in
            XCTAssertEqual(error as? XMLTVParserError, .invalidDate("bad-date"))
        }
    }
}
