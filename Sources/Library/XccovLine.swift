import Foundation

enum XccovLine: Sendable {
    case branchStart(Int, Int)
    case branchNull(Int)
    case branch(Int, Int, Int)
    case normal(Int, Int)
}

extension XccovLine {
    private static let branchStartRegex = try! NSRegularExpression(pattern: #"(\d+): (\d+) \["#)
    private static let branchNullRegex = try! NSRegularExpression(pattern: #"(\d+): \* \["#)
    private static let branchRegex = try! NSRegularExpression(pattern: #"\((\d+), (\d+), (\d+)\)"#)
    private static let normalRegex = try! NSRegularExpression(pattern: #"(\d+): (\d+)"#)

    static func from(_ input: String) -> Self? {
        func check(with regex: NSRegularExpression) -> NSTextCheckingResult? {
            regex.firstMatch(in: input, options: [], range: .init(location: 0, length: input.utf16.count))
        }

        func int(at index: Int, in result: NSTextCheckingResult) -> Int {
            let nsRange = result.range(at: index)
            let range = Range(nsRange, in: input)!
            // Sometimes xccov produces big integers, causing overflow.
            return Int(input[range]) ?? 1
        }

        if let match = check(with: branchStartRegex) {
            return .branchStart(int(at: 1, in: match), int(at: 2, in: match))
        }
        if let match = check(with: branchNullRegex) {
            return .branchNull(int(at: 1, in: match))
        }
        if let match = check(with: branchRegex) {
            return .branch(int(at: 1, in: match), int(at: 2, in: match), int(at: 3, in: match))
        }
        if let match = check(with: normalRegex) {
            return .normal(int(at: 1, in: match), int(at: 2, in: match))
        }
        return nil
    }
}

struct XccovProcessor {
    let relativePath: String
    init(relativePath: String) {
        self.relativePath = relativePath
    }

    private var sum: [(Int, CodecovLine)] = []
    private var branchedLine: (Int, Int, Int)?

    private mutating func updateBranchedLine(covered: Bool) {
        guard let (lineNo, numerator, denominator) = branchedLine else {
            return
        }
        branchedLine = (lineNo, numerator + (covered ? 1 : 0), denominator + 1)
    }

    private mutating func addBranchedLineIfNeeded() {
        guard let (lineNo, numerator, denominator) = branchedLine else { return }
        branchedLine = nil
        sum.append((lineNo, .quotient(numerator: numerator, denominator: denominator)))
    }

    private mutating func addLine(lineNo: Int, line: CodecovLine) {
        addBranchedLineIfNeeded()
        let prevLineNo = sum.last?.0 ?? -1
        guard lineNo > prevLineNo else {
            assertionFailure("Lines must be processed in ascending order.")
            return
        }
        sum.append((lineNo, line))
    }

    mutating func process(line: String) {
        guard let lexed = XccovLine.from(line) else {
            addBranchedLineIfNeeded()
            return
        }

        switch lexed {
        case let .branchStart(lineNo, baseCount):
            branchedLine = (lineNo, baseCount == 0 ? 0 : 1, 1)
        case let .branchNull(lineNo):
            branchedLine = (lineNo, 0, 0)
        case let .branch(_, _, count):
            updateBranchedLine(covered: count > 0)
        case let .normal(lineNo, count):
            addLine(lineNo: lineNo, line: count == 0 ? .zero : .full)
        }
    }

    mutating func finalize() -> [CodecovLine] {
        addBranchedLineIfNeeded()
        var i = 0
        var list: [CodecovLine] = []
        for (lineNo, line) in sum {
            while i < lineNo {
                list.append(.null)
                i += 1
            }
            list.append(line.normalized)
            i += 1
        }
        return list
    }
}
