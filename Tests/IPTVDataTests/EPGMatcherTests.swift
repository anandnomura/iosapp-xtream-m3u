import Foundation
import IPTVDomain
import XCTest
@testable import IPTVData

final class EPGMatcherTests: XCTestCase {
    func testNowNextMatchesByExactChannelID() {
        let matcher = EPGMatcher()
        let referenceDate = Date(timeIntervalSince1970: 1_800_000_000)
        let item = MediaItem(
            id: "bbc1.uk",
            providerID: UUID(),
            groupID: "news",
            kind: .live,
            title: "BBC One"
        )

        let epg = ParsedEPG(
            channels: [
                EPGChannel(id: "bbc1.uk", displayName: "BBC One")
            ],
            programmes: [
                EPGProgramme(
                    id: "1",
                    channelID: "bbc1.uk",
                    title: "Breakfast",
                    startDate: referenceDate.addingTimeInterval(-600),
                    endDate: referenceDate.addingTimeInterval(1800)
                ),
                EPGProgramme(
                    id: "2",
                    channelID: "bbc1.uk",
                    title: "Morning Live",
                    startDate: referenceDate.addingTimeInterval(1800),
                    endDate: referenceDate.addingTimeInterval(3600)
                )
            ]
        )

        let map = matcher.nowNextMap(for: [item], epg: epg, at: referenceDate)

        XCTAssertEqual(map[item.id]?.current?.title, "Breakfast")
        XCTAssertEqual(map[item.id]?.next?.title, "Morning Live")
    }

    func testNowNextFallsBackToDisplayNameMatching() {
        let matcher = EPGMatcher()
        let referenceDate = Date(timeIntervalSince1970: 1_800_000_000)
        let item = MediaItem(
            id: "provider-stream-42",
            providerID: UUID(),
            groupID: "sports",
            kind: .live,
            title: "ESPN HD"
        )

        let epg = ParsedEPG(
            channels: [
                EPGChannel(id: "espn.us", displayName: "ESPN HD")
            ],
            programmes: [
                EPGProgramme(
                    id: "3",
                    channelID: "espn.us",
                    title: "SportsCenter",
                    startDate: referenceDate.addingTimeInterval(-1200),
                    endDate: referenceDate.addingTimeInterval(1200)
                )
            ]
        )

        let map = matcher.nowNextMap(for: [item], epg: epg, at: referenceDate)

        XCTAssertEqual(map[item.id]?.channelID, "espn.us")
        XCTAssertEqual(map[item.id]?.current?.title, "SportsCenter")
    }
}
