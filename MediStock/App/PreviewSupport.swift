#if DEBUG
import Foundation

// MARK: - Medicine

struct PreviewMedicineRepository: MedicineRepository {
    var medicines: [Medicine] = [
        Medicine(id: "preview-1", name: "Doliprane", stock: 12, aisle: "Aisle 1"),
        Medicine(id: "preview-2", name: "Ibuprofène", stock: 4, aisle: "Aisle 2")
    ]

    func fetchMedicines() async throws -> [Medicine] { medicines }
    func save(_ medicine: Medicine) async throws {}
    func updateStock(medicineId: String, newStock: Int) async throws {}
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

extension MedicineStockViewModel {
    @MainActor
    static var preview: MedicineStockViewModel {
        let container = DIContainer.preview
        return MedicineStockViewModel(
            medicineRepository: container.medicineRepository,
            historyRepository: container.historyRepository,
            authService: container.authService
        )
    }
}
#endif
