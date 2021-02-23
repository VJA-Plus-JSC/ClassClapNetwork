import XCTest
@testable import ClassClapNetwork

final class ClassClapNetworkTests: XCTestCase {
    func testGET() {
        let url = "https://jsonplaceholder.typicode.com/posts/1/comments"
        Network.shared.sendRequest(as: .get, to: url) {
            if case .success(_) = $0 {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }
        }
    }
    
    func testPost() {
        let url = "https://jsonplaceholder.typicode.com/posts"
        Network.shared.sendRequest(to: url) { result in
            switch result {
            case .failure(_):
                XCTAssertTrue(false)
            case .success(_):
                XCTAssertTrue(true)
            }
        }
    }

    static var allTests = [
        ("testGET", testGET),
        ("testPOST", testPost),
    ]
}
