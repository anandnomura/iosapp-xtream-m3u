import Foundation
import XCTest
import IPTVDomain
@testable import IPTVData

final class XMLTVGuideLoaderTests: XCTestCase {
    func testLoaderParsesGuideFromRawTextSource() async throws {
        let loader = XMLTVGuideLoader()
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <tv>
          <channel id="bbc1.uk">
            <display-name>BBC One</display-name>
          </channel>
          <programme start="20260414060000 +0000" stop="20260414070000 +0000" channel="bbc1.uk">
            <title>Breakfast</title>
          </programme>
        </tv>
        """

        let parsed = try await loader.load(source: .init(rawText: xml))

        XCTAssertEqual(parsed.channels.count, 1)
        XCTAssertEqual(parsed.programmes.count, 1)
        XCTAssertEqual(parsed.programmes.first?.title, "Breakfast")
    }
}
