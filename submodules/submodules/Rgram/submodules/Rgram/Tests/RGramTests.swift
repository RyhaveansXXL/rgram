import Foundation
import XCTest
@testable import RGram

final class RGramTests: XCTestCase {
    func testProfilesDecoding() {
        let json = #"{"profiles":{"42":{"banner":"https://x.example/b.jpg","premium":true},"7":{"banner":"http://insecure.example/b.jpg"},"bad":{}}}"#
        let result = RGramProfile.decodeProfiles(Data(json.utf8))
        XCTAssertEqual(result[42]?.isPremium, true)
        XCTAssertEqual(result[42]?.bannerURL?.absoluteString, "https://x.example/b.jpg")
        XCTAssertNil(result[7]?.bannerURL)
        XCTAssertEqual(result.count, 2)
    }

    func testUpdateParsing() {
        let json = #"{"tag_name":"build-120","name":"R Gram 13.2 (120)","html_url":"https://github.com/o/r/releases/tag/build-120","assets":[{"name":"RGram.ipa","browser_download_url":"https://github.com/o/r/releases/download/build-120/RGram.ipa"}]}"#
        let update = RGramUpdateChecker.parse(Data(json.utf8))
        XCTAssertEqual(update?.buildNumber, 120)
        XCTAssertEqual(update?.ipaURL?.lastPathComponent, "RGram.ipa")
        XCTAssertNil(RGramUpdateChecker.parse(Data(#"{"tag_name":"v1","html_url":"https://x","assets":[]}"#.utf8)))
    }
}
