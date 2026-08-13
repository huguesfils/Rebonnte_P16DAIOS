import Foundation

struct StockChange: Equatable, Sendable {
    let previous: Int
    let new: Int

    var delta: Int { new - previous }
}
