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

    func loadHistory(for medicine: Medicine) async {
        do {
            history = try await historyRepository.fetchHistory(medicineId: medicine.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func medicines(inAisle aisle: String) -> [Medicine] {
        medicines.filter { $0.aisle == aisle }
    }

    // MARK: - Write

    func addRandomMedicine() async {
        guard let user = authService.currentUser else {
            errorMessage = MediStockError.notAuthenticated.localizedDescription
            return
        }

        let medicine = Medicine(
            name: "Medicine \(Int.random(in: 1...100))",
            stock: Int.random(in: 1...100),
            aisle: "Aisle \(Int.random(in: 1...10))"
        )

        do {
            try await medicineRepository.save(medicine)
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        await recordHistory(
            medicineId: medicine.id,
            user: user,
            action: "Added \(medicine.name)",
            details: "Added new medicine"
        )
        await loadMedicines()
    }

    func updateMedicine(_ medicine: Medicine) async {
        guard let user = authService.currentUser else {
            errorMessage = MediStockError.notAuthenticated.localizedDescription
            return
        }

        do {
            try await medicineRepository.save(medicine)
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        if let index = medicines.firstIndex(where: { $0.id == medicine.id }) {
            medicines[index] = medicine
        }

        await recordHistory(
            medicineId: medicine.id,
            user: user,
            action: "Updated \(medicine.name)",
            details: "Updated medicine details"
        )
    }

    func increaseStock(_ medicine: Medicine) async {
        await updateStock(medicine, by: 1)
    }

    func decreaseStock(_ medicine: Medicine) async {
        await updateStock(medicine, by: -1)
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

    private func updateStock(_ medicine: Medicine, by amount: Int) async {
        guard let user = authService.currentUser else {
            errorMessage = MediStockError.notAuthenticated.localizedDescription
            return
        }

        let newStock = medicine.stock + amount

        do {
            try await medicineRepository.updateStock(medicineId: medicine.id, newStock: newStock)
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        if let index = medicines.firstIndex(where: { $0.id == medicine.id }) {
            medicines[index].stock = newStock
        }

        await recordHistory(
            medicineId: medicine.id,
            user: user,
            action: "\(amount > 0 ? "Increased" : "Decreased") stock of \(medicine.name) by \(amount)",
            details: "Stock changed from \(medicine.stock) to \(newStock)"
        )
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
