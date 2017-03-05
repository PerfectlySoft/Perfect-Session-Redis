import XCTest
@testable import Perfect_Session_Redis

class Perfect_Session_RedisTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(Perfect_Session_Redis().text, "Hello, World!")
    }


    static var allTests : [(String, (Perfect_Session_RedisTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
