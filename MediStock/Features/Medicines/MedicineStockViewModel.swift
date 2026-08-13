import Foundation

@Observable
@MainActor
final class MedicineStockViewModel {
    private(set) var medicines: [Medicine] = []
    private(set) var history: [HistoryEntry] = []
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

    func loadMedicines() async {
        do {
            medicines = try await medicineRepository.fetchMedicines()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadHistory(forMedicineId medicineId: String) async {
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

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAisle = aisle.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, !trimmedAisle.isEmpty, stock >= 0 else {
            errorMessage = MediStockError.invalidData.localizedDescription
            return false
        }

        let medicine = Medicine(name: trimmedName, stock: stock, aisle: trimmedAisle)

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
            details: "Created with stock \(stock) in \(trimmedAisle)"
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

        let previousName = updated.name
        let previousAisle = updated.aisle
        updated.name = name
        updated.aisle = aisle

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
        await updateStock(medicineId: medicineId, by: 1)
    }

    func decreaseStock(medicineId: String) async {
        await updateStock(medicineId: medicineId, by: -1)
    }

    func setStock(medicineId: String, to newStock: Int) async {
        guard let current = medicine(withId: medicineId) else {
            errorMessage = MediStockError.medicineNotFound.localizedDescription
            return
        }

        await updateStock(medicineId: medicineId, by: newStock - current.stock)
    }

    func delete(_ medicine: Medicine) async {
        guard let user = authService.currentUser else {
            errorMessage = MediStockError.notAuthenticated.localizedDescription
            return
        }

        do {
            try await medicineRepository.delete(medicineId: medicine.id)
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        await recordHistory(
            medicineId: medicine.id,
            user: user,
            action: "Deleted \(medicine.name)",
            details: "Removed medicine"
        )
        await loadMedicines()
    }

    // MARK: - Private

    private func updateStock(medicineId: String, by amount: Int) async {
        guard let user = authService.currentUser else {
            errorMessage = MediStockError.notAuthenticated.localizedDescription
            return
        }

        guard let current = medicine(withId: medicineId) else {
            errorMessage = MediStockError.medicineNotFound.localizedDescription
            return
        }

        guard amount != 0 else { return }

        let previousStock = current.stock
        let newStock = previousStock + amount

        do {
            try await medicineRepository.updateStock(medicineId: medicineId, newStock: newStock)
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        var updated = current
        updated.stock = newStock
        apply(updated)

        await recordHistory(
            medicineId: medicineId,
            user: user,
            action: "\(amount > 0 ? "Increased" : "Decreased") stock of \(current.name) by \(abs(amount))",
            details: "Stock changed from \(previousStock) to \(newStock)"
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
