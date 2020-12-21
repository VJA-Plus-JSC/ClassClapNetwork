import XCTest
@testable import ClassClapNetwork

final class ClassClapNetworkTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let url = "https://jsonplaceholder.typicode.com/todos/1"
        Network.shared.sendPostRequest(to: url) { result in
            switch result {
            case .failure(_):
                XCTAssertTrue(false)
            case .success(_):
                XCTAssertTrue(true)
            }
        }
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
