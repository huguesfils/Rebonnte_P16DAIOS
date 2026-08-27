import Foundation

struct NetworkAwareMedicineRepository: MedicineRepository {
    private let wrapped: MedicineRepository
    private let networkMonitor: NetworkMonitor

    init(wrapping wrapped: MedicineRepository, networkMonitor: NetworkMonitor) {
        self.wrapped = wrapped
        self.networkMonitor = networkMonitor
    }

    // MARK: - Read

    func fetchMedicines() async throws -> [Medicine] {
        try requireConnection()
        return try await wrapped.fetchMedicines()
    }

    // MARK: - Write

    func save(_ medicine: Medicine) async throws {
        try requireConnection()
        try await wrapped.save(medicine)
    }

    func adjustStock(medicineId: String, by amount: Int) async throws -> StockChange {
        try requireConnection()
        return try await wrapped.adjustStock(medicineId: medicineId, by: amount)
    }

    func setStock(medicineId: String, to newStock: Int) async throws -> StockChange {
        try requireConnection()
        return try await wrapped.setStock(medicineId: medicineId, to: newStock)
    }

    func delete(medicineId: String) async throws {
        try requireConnection()
        try await wrapped.delete(medicineId: medicineId)
    }

    // MARK: - Connectivity

    private func requireConnection() throws {
        guard networkMonitor.isConnected else {
            throw MediStockError.networkUnavailable
        }
    }
}
