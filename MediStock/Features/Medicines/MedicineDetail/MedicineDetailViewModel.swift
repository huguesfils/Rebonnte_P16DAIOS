import Foundation

@Observable
@MainActor
final class MedicineDetailViewModel {
    let medicineId: String

    private(set) var history: [HistoryEntry] = []
    private(set) var isLoadingHistory = false
    var errorMessage: String?

    var medicine: Medicine? { store.medicines.first { $0.id == medicineId } }

    private let store: MedicineStore
    private let historyRepository: HistoryRepository

    init(medicineId: String, store: MedicineStore, historyRepository: HistoryRepository) {
        self.medicineId = medicineId
        self.store = store
        self.historyRepository = historyRepository
    }

    // MARK: - Read

    func loadHistory() async {
        isLoadingHistory = true
        defer { isLoadingHistory = false }

        do {
            history = try await historyRepository.fetchHistory(medicineId: medicineId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Write

    func increaseStock() async {
        await perform { try await store.adjustStock(medicineId: medicineId, by: 1) }
    }

    func decreaseStock() async {
        await perform { try await store.adjustStock(medicineId: medicineId, by: -1) }
    }

    func setStock(to newStock: Int) async {
        await perform { try await store.setStock(medicineId: medicineId, to: newStock) }
    }

    func updateDetails(name: String, aisle: String) async {
        await perform { try await store.updateDetails(medicineId: medicineId, name: name, aisle: aisle) }
    }

    func delete() async -> Bool {
        do {
            try await store.delete(medicineId: medicineId)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Private

    private func perform(_ mutation: () async throws -> Void) async {
        do {
            try await mutation()
            await loadHistory()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
