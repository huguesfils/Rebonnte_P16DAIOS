import Foundation

struct Medicine: Identifiable, Equatable, Sendable {
    let id: String
    var name: String
    var stock: Int
    var aisle: String

    init(id: String = UUID().uuidString, name: String, stock: Int, aisle: String) {
        self.id = id
        self.name = name
        self.stock = stock
        self.aisle = aisle
    }
}
