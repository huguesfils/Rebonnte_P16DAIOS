import Foundation

protocol MedicineRepository: Sendable {
    func fetchMedicines() async throws -> [Medicine]
    func save(_ medicine: Medicine) async throws
    func updateStock(medicineId: String, newStock: Int) async throws
    func delete(medicineId: String) async throws
}
