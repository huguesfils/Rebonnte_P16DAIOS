import Foundation
@testable import MediStock

final class MockMedicineRepository: MedicineRepository, @unchecked Sendable {
    var storedMedicines: [String: Medicine] = [:]
    var errorToThrow: Error?

    private(set) var fetchCallCount = 0
    private(set) var savedMedicines: [Medicine] = []
    private(set) var updatedStocks: [(medicineId: String, newStock: Int)] = []
    private(set) var deletedIds: [String] = []

    init(medicines: [Medicine] = []) {
        storedMedicines = Dictionary(uniqueKeysWithValues: medicines.map { ($0.id, $0) })
    }

    func fetchMedicines() async throws -> [Medicine] {
        fetchCallCount += 1
        if let errorToThrow { throw errorToThrow }
        return storedMedicines.values.sorted { $0.id < $1.id }
    }

    func save(_ medicine: Medicine) async throws {
        if let errorToThrow { throw errorToThrow }
        storedMedicines[medicine.id] = medicine
        savedMedicines.append(medicine)
    }

    func adjustStock(medicineId: String, by amount: Int) async throws -> StockChange {
        try await commitStockChange(medicineId: medicineId) { $0 + amount }
    }

    func setStock(medicineId: String, to newStock: Int) async throws -> StockChange {
        try await commitStockChange(medicineId: medicineId) { _ in newStock }
    }

    private func commitStockChange(medicineId: String, resolve: (Int) -> Int) async throws -> StockChange {
        if let errorToThrow { throw errorToThrow }

        guard let previous = storedMedicines[medicineId]?.stock else {
            throw MediStockError.medicineNotFound
        }

        let resolved = resolve(previous)
        guard resolved >= 0 else { throw MediStockError.negativeStock }

        if resolved != previous {
            storedMedicines[medicineId]?.stock = resolved
            updatedStocks.append((medicineId, resolved))
        }
        return StockChange(previous: previous, new: resolved)
    }

    func delete(medicineId: String) async throws {
        if let errorToThrow { throw errorToThrow }
        storedMedicines[medicineId] = nil
        deletedIds.append(medicineId)
    }
}
