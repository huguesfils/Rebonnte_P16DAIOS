import Foundation

@Observable
@MainActor
final class MedicineStore {
    private(set) var medicines: [Medicine] = []
    private(set) var isLoading = false
    private(set) var loadedForUserId: String?
    private(set) var loadError: String?

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

    func loadIfNeeded() async {
        let userId = authService.currentUser?.id
        guard loadedForUserId != userId, !isLoading else { return }

        medicines = []
        await load()
    }

    func refresh() async {
        await load()
    }

    // MARK: - Write

    func addMedicine(name: String, stock: Int, aisle: String) async throws {
        guard let user = authService.currentUser else {
            throw MediStockError.notAuthenticated
        }

        let input = try MedicineInput(name: name, aisle: aisle, stock: stock)
        let medicine = Medicine(name: input.name, stock: input.stock, aisle: input.aisle)

        try await medicineRepository.save(medicine)

        try await recordHistoryThenReload(
            medicineId: medicine.id,
            user: user,
            action: "Ajout de \(medicine.name)",
            details: "Créé avec un stock de \(input.stock) dans \(input.aisle)"
        )
    }

    func updateDetails(medicineId: String, name: String, aisle: String) async throws {
        guard let user = authService.currentUser else {
            throw MediStockError.notAuthenticated
        }

        guard var updated = medicine(withId: medicineId) else {
            throw MediStockError.medicineNotFound
        }

        let input = try MedicineInput(name: name, aisle: aisle, stock: updated.stock)

        let previousName = updated.name
        let previousAisle = updated.aisle
        updated.name = input.name
        updated.aisle = input.aisle

        guard updated.name != previousName || updated.aisle != previousAisle else { return }

        try await medicineRepository.save(updated)

        apply(updated)

        try await recordHistory(
            medicineId: medicineId,
            user: user,
            action: "Modification de \(updated.name)",
            details: "Nom : \(previousName) → \(updated.name) · Rayon : \(previousAisle) → \(updated.aisle)"
        )
    }

    func adjustStock(medicineId: String, by amount: Int) async throws {
        try await commitStockChange(medicineId: medicineId) { repository in
            try await repository.adjustStock(medicineId: medicineId, by: amount)
        }
    }

    func setStock(medicineId: String, to newStock: Int) async throws {
        try await commitStockChange(medicineId: medicineId) { repository in
            try await repository.setStock(medicineId: medicineId, to: newStock)
        }
    }

    func delete(medicineId: String) async throws {
        guard let user = authService.currentUser else {
            throw MediStockError.notAuthenticated
        }

        guard let medicine = medicine(withId: medicineId) else {
            throw MediStockError.medicineNotFound
        }

        try await medicineRepository.delete(medicineId: medicineId)

        try await recordHistoryThenReload(
            medicineId: medicineId,
            user: user,
            action: "Suppression de \(medicine.name)",
            details: "Retiré de \(medicine.aisle), stock de \(medicine.stock)"
        )
    }

    // MARK: - Private

    private func load() async {
        isLoading = true
        let userId = authService.currentUser?.id
        defer { isLoading = false }

        do {
            medicines = try await medicineRepository.fetchMedicines()
            loadedForUserId = userId
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func medicine(withId id: String) -> Medicine? {
        medicines.first { $0.id == id }
    }

    private func apply(_ medicine: Medicine) {
        guard let index = medicines.firstIndex(where: { $0.id == medicine.id }) else { return }
        medicines[index] = medicine
    }

    private func commitStockChange(
        medicineId: String,
        write: (MedicineRepository) async throws -> StockChange
    ) async throws {
        guard let user = authService.currentUser else {
            throw MediStockError.notAuthenticated
        }

        guard let current = medicine(withId: medicineId) else {
            throw MediStockError.medicineNotFound
        }

        let change = try await write(medicineRepository)

        guard change.delta != 0 else { return }

        var updated = current
        updated.stock = change.new
        apply(updated)

        try await recordHistory(
            medicineId: medicineId,
            user: user,
            action: "Stock de \(current.name) \(change.delta > 0 ? "augmenté" : "diminué") de \(abs(change.delta))",
            details: "Stock passé de \(change.previous) à \(change.new)"
        )
    }

    private func recordHistory(medicineId: String, user: AppUser, action: String, details: String) async throws {
        let entry = HistoryEntry(
            medicineId: medicineId,
            user: user.id,
            userEmail: user.email,
            action: action,
            details: details
        )

        try await historyRepository.addEntry(entry)
    }

    private func recordHistoryThenReload(
        medicineId: String,
        user: AppUser,
        action: String,
        details: String
    ) async throws {
        var historyError: Error?
        do {
            try await recordHistory(medicineId: medicineId, user: user, action: action, details: details)
        } catch {
            historyError = error
        }

        await load()

        if let historyError { throw historyError }
    }
}
