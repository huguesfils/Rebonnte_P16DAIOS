import Foundation

@Observable
@MainActor
final class MedicineStockViewModel {
    private(set) var medicines: [Medicine] = []
    private(set) var history: [HistoryEntry] = []
    private(set) var isLoadingMedicines = false
    private(set) var isLoadingHistory = false
    private(set) var hasLoadedMedicines = false
    var errorMessage: String?

    var aisles: [String] {
        Array(Set(medicines.map(\.aisle))).sorted()
    }

    private let medicineRepository: MedicineRepository
    private let historyRepository: HistoryRepository
    private let authService: AuthService

    init(
        medicineRepository: MedicineRepository,
        historyRepository: HistoryRepository,
        authService: AuthService
    ) {
        self.medicineRepository = medicineRepository
        self.historyRepository = historyRepository
        self.authService = authService
    }

    // MARK: - Read

    func loadMedicinesIfNeeded() async {
        guard !hasLoadedMedicines, !isLoadingMedicines else { return }
        await loadMedicines()
    }

    func loadMedicines() async {
        isLoadingMedicines = true
        defer {
            isLoadingMedicines = false
            hasLoadedMedicines = true
        }

        do {
            medicines = try await medicineRepository.fetchMedicines()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadHistory(forMedicineId medicineId: String) async {
        isLoadingHistory = true
        defer { isLoadingHistory = false }

        do {
            history = try await historyRepository.fetchHistory(medicineId: medicineId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func medicines(inAisle aisle: String) -> [Medicine] {
        medicines.filter { $0.aisle == aisle }
    }

    func medicine(withId id: String) -> Medicine? {
        medicines.first { $0.id == id }
    }

    // MARK: - Write

    @discardableResult
    func addMedicine(name: String, stock: Int, aisle: String) async -> Bool {
        guard let user = authService.currentUser else {
            errorMessage = MediStockError.notAuthenticated.localizedDescription
            return false
        }

        let input: MedicineInput
        do {
            input = try MedicineInput(name: name, aisle: aisle, stock: stock)
        } catch {
            errorMessage = error.localizedDescription
            return false
        }

        let medicine = Medicine(name: input.name, stock: input.stock, aisle: input.aisle)

        do {
            try await medicineRepository.save(medicine)
        } catch {
            errorMessage = error.localizedDescription
            return false
        }

        await recordHistory(
            medicineId: medicine.id,
            user: user,
            action: "Added \(medicine.name)",
            details: "Created with stock \(input.stock) in \(input.aisle)"
        )
        await loadMedicines()
        return true
    }

    func updateDetails(medicineId: String, name: String, aisle: String) async {
        guard let user = authService.currentUser else {
            errorMessage = MediStockError.notAuthenticated.localizedDescription
            return
        }

        guard var updated = medicine(withId: medicineId) else {
            errorMessage = MediStockError.medicineNotFound.localizedDescription
            return
        }

        let input: MedicineInput
        do {
            input = try MedicineInput(name: name, aisle: aisle, stock: updated.stock)
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        let previousName = updated.name
        let previousAisle = updated.aisle
        updated.name = input.name
        updated.aisle = input.aisle

        guard updated.name != previousName || updated.aisle != previousAisle else { return }

        do {
            try await medicineRepository.save(updated)
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        apply(updated)

        await recordHistory(
            medicineId: medicineId,
            user: user,
            action: "Updated \(updated.name)",
            details: "Name \(previousName) → \(updated.name), aisle \(previousAisle) → \(updated.aisle)"
        )
    }

    func increaseStock(medicineId: String) async {
        await adjustStock(medicineId: medicineId, by: 1)
    }

    func decreaseStock(medicineId: String) async {
        await adjustStock(medicineId: medicineId, by: -1)
    }

    private func adjustStock(medicineId: String, by amount: Int) async {
        await commitStockChange(medicineId: medicineId) { repository in
            try await repository.adjustStock(medicineId: medicineId, by: amount)
        }
    }

    func setStock(medicineId: String, to newStock: Int) async {
        await commitStockChange(medicineId: medicineId) { repository in
            try await repository.setStock(medicineId: medicineId, to: newStock)
        }
    }

    @discardableResult
    func delete(medicineId: String) async -> Bool {
        guard let user = authService.currentUser else {
            errorMessage = MediStockError.notAuthenticated.localizedDescription
            return false
        }

        guard let medicine = medicine(withId: medicineId) else {
            errorMessage = MediStockError.medicineNotFound.localizedDescription
            return false
        }

        do {
            try await medicineRepository.delete(medicineId: medicineId)
        } catch {
            errorMessage = error.localizedDescription
            return false
        }

        await recordHistory(
            medicineId: medicineId,
            user: user,
            action: "Deleted \(medicine.name)",
            details: "Removed from \(medicine.aisle), stock was \(medicine.stock)"
        )
        await loadMedicines()
        return true
    }

    func delete(atOffsets offsets: IndexSet, in medicines: [Medicine]) async {
        let ids = offsets.compactMap { medicines.indices.contains($0) ? medicines[$0].id : nil }

        for id in ids {
            await delete(medicineId: id)
        }
    }

    // MARK: - Private

    private func commitStockChange(
        medicineId: String,
        write: (MedicineRepository) async throws -> StockChange
    ) async {
        guard let user = authService.currentUser else {
            errorMessage = MediStockError.notAuthenticated.localizedDescription
            return
        }

        guard let current = medicine(withId: medicineId) else {
            errorMessage = MediStockError.medicineNotFound.localizedDescription
            return
        }

        let change: StockChange
        do {
            change = try await write(medicineRepository)
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        guard change.delta != 0 else { return }

        var updated = current
        updated.stock = change.new
        apply(updated)

        await recordHistory(
            medicineId: medicineId,
            user: user,
            action: "\(change.delta > 0 ? "Increased" : "Decreased") stock of \(current.name) by \(abs(change.delta))",
            details: "Stock changed from \(change.previous) to \(change.new)"
        )
    }

    private func apply(_ medicine: Medicine) {
        guard let index = medicines.firstIndex(where: { $0.id == medicine.id }) else { return }
        medicines[index] = medicine
    }

    private func recordHistory(medicineId: String, user: AppUser, action: String, details: String) async {
        let entry = HistoryEntry(
            medicineId: medicineId,
            user: user.id,
            userEmail: user.email,
            action: action,
            details: details
        )

        do {
            try await historyRepository.addEntry(entry)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
