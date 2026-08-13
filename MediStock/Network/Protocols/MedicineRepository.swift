import Foundation

protocol MedicineRepository: Sendable {
    func fetchMedicines() async throws -> [Medicine]
    func save(_ medicine: Medicine) async throws
    func adjustStock(medicineId: String, by amount: Int) async throws -> StockChange
    func setStock(medicineId: String, to newStock: Int) async throws -> StockChange
    func delete(medicineId: String) async throws
}
