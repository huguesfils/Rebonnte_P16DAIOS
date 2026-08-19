#if DEBUG
import Foundation

// MARK: - Medicine

struct PreviewMedicineRepository: MedicineRepository {
    var medicines: [Medicine] = [
        Medicine(id: "preview-1", name: "Doliprane", stock: 12, aisle: "Rayon 1"),
        Medicine(id: "preview-2", name: "Ibuprofène", stock: 4, aisle: "Rayon 2")
    ]

    func fetchMedicines() async throws -> [Medicine] { medicines }
    func save(_ medicine: Medicine) async throws {}
    func adjustStock(medicineId: String, by amount: Int) async throws -> StockChange {
        StockChange(previous: 0, new: amount)
    }

    func setStock(medicineId: String, to newStock: Int) async throws -> StockChange {
        StockChange(previous: 0, new: newStock)
    }
    func delete(medicineId: String) async throws {}
}

// MARK: - History

struct PreviewHistoryRepository: HistoryRepository {
    func fetchHistory(medicineId: String) async throws -> [HistoryEntry] { [] }
    func addEntry(_ entry: HistoryEntry) async throws {}
}

// MARK: - Auth

struct PreviewAuthService: AuthService {
    var currentUser: AppUser? = AppUser(id: "preview-user", email: "preview@medistock.app")

    func signIn(email: String, password: String) async throws -> AppUser {
        AppUser(id: "preview-user", email: email)
    }

    func signUp(email: String, password: String) async throws -> AppUser {
        AppUser(id: "preview-user", email: email)
    }

    func signOut() throws {}

    func observeAuthState(
        _ onChange: @escaping @Sendable @MainActor (AppUser?) -> Void
    ) -> any AuthStateObservation {
        let user = currentUser
        Task { @MainActor in
            onChange(user)
        }
        return PreviewAuthStateObservation()
    }
}

struct PreviewAuthStateObservation: AuthStateObservation {
    func cancel() {}
}

// MARK: - Container

extension DIContainer {
    @MainActor
    static var preview: DIContainer {
        DIContainer(
            medicineRepository: PreviewMedicineRepository(),
            historyRepository: PreviewHistoryRepository(),
            authService: PreviewAuthService()
        )
    }
}

#endif
