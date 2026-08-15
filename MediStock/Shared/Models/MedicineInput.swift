import Foundation

struct MedicineInput: Equatable, Sendable {
    let name: String
    let aisle: String
    let stock: Int

    init(name: String, aisle: String, stock: Int) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAisle = aisle.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, !trimmedAisle.isEmpty else {
            throw MediStockError.invalidData
        }
        guard stock >= 0 else {
            throw MediStockError.negativeStock
        }

        self.name = trimmedName
        self.aisle = trimmedAisle
        self.stock = stock
    }

    static func isValid(name: String, aisle: String, stock: Int) -> Bool {
        (try? MedicineInput(name: name, aisle: aisle, stock: stock)) != nil
    }
}
