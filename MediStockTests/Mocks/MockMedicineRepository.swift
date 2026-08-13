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

    func updateStock(medicineId: String, newStock: Int) async throws {
        if let errorToThrow { throw errorToThrow }
        storedMedicines[medicineId]?.stock = newStock
        updatedStocks.append((medicineId, newStock))
    }

    func delete(medicineId: String) async throws {
        if let errorToThrow { throw errorToThrow }
        storedMedicines[medicineId] = nil
        deletedIds.append(medicineId)
    }
}
