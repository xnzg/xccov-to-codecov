import XCTest
@testable import Library

final class ProcessorTests: XCTestCase {
    func testBasic() {
        var processor = XccovProcessor(relativePath: "/foo")

        processor.process(line: "1: 1")
        processor.process(line: "2: *")
        processor.process(line: "4: 0")

        XCTAssertEqual(
            processor.finalize(),
            [.full, .null, .null, .zero])
    }

    func testBranchCase1() {
        var processor = XccovProcessor(relativePath: "/foo")

        let input = """
        1: *
        2: 10
        3: 13 [
        (3, 3, 5)
        ]
        4: 14 [
        (4, 4, 8)
        ]
        5: 15 [
        (3, 3, 8)
        (4, 4, 8)
        ]
        6: 10
        """

        for line in input.split(separator: "\n") {
            processor.process(line: String(line))
        }

        XCTAssertEqual(
            processor.finalize(),
            [.null, .full, .full, .full, .full, .full])
    }

    func testBranchCase2() {
        var processor = XccovProcessor(relativePath: "/foo")

        let input = """
        1: 1 [
        (2, 2, 0)
        (3, 3, 1)
        ]
        2: 10
        """

        for line in input.split(separator: "\n") {
            processor.process(line: String(line))
        }

        XCTAssertEqual(
            processor.finalize(),
            [.quotient(numerator: 2, denominator: 3), .full])
    }

    func testBranchCase3() {
        var processor = XccovProcessor(relativePath: "/foo")

        let input = """
        1: * [
        (2, 2, 0)
        (3, 3, 1)
        ]
        2: 10
        """

        for line in input.split(separator: "\n") {
            processor.process(line: String(line))
        }

        XCTAssertEqual(
            processor.finalize(),
            [.quotient(numerator: 1, denominator: 2), .full])
    }
}
