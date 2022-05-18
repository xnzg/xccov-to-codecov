import Foundation

enum CodecovLine: Sendable {
    case null
    case zero
    case full
    case quotient(numerator: Int, denominator: Int)

    var normalized: Self {
        guard case let .quotient(numerator, denominator) = self else {
            return self
        }
        if numerator == 0 {
            return .zero
        }
        if numerator == denominator {
            return .full
        }
        return self
    }
}

extension CodecovLine: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .zero:
            try container.encode(0)
        case .full:
            try container.encode(1)
        case .quotient(let numerator, let denominator):
            try container.encode("\(numerator)/\(denominator)")
        }
    }
}
