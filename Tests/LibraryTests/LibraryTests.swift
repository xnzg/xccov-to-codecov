import XCTest
@testable import Library

private func processedLines(from input: String) -> [CodecovLine] {
    var processor = XccovProcessor(relativePath: "/foo")

    for line in input.split(separator: "\n") {
        processor.process(line: String(line))
    }

    let finalized = processor.finalize()
    guard let first = finalized.first else { return [] }
    XCTAssertEqual(first, .null)
    return Array(finalized.dropFirst())
}

final class ProcessorTests: XCTestCase {
    func testBasic() {
        let lines = processedLines(from: """
        1: 1
        2: *
        4: 0
        """)

        XCTAssertEqual(
            lines,
            [.full, .null, .null, .zero])
    }

    func testManyZeros() {
        let lines = processedLines(from: """
        1: *
        2: *
        3: 0
        4: 0
        """)

        XCTAssertEqual(
            lines,
            [.null, .null, .zero, .zero])
    }

    func testBranchCase1() {
        let lines = processedLines(from: """
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
        """)

        XCTAssertEqual(
            lines,
            [.null, .full, .full, .full, .full, .full])
    }

    func testBranchCase2() {
        let lines = processedLines(from: """
        1: 1 [
        (2, 2, 0)
        (3, 3, 1)
        ]
        2: 10
        """)

        XCTAssertEqual(
            lines,
            [.quotient(numerator: 2, denominator: 3), .full])
    }

    func testBranchCase3() {
        let lines = processedLines(from: """
        1: * [
        (2, 2, 0)
        (3, 3, 1)
        ]
        2: 10
        """)

        XCTAssertEqual(
            lines,
            [.quotient(numerator: 1, denominator: 2), .full])
    }
}
