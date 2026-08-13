import Foundation

struct DIContainer {
    let medicineRepository: MedicineRepository
    let historyRepository: HistoryRepository
    let authService: AuthService
    let sessionViewModel: SessionViewModel

    @MainActor
    init(
        medicineRepository: MedicineRepository,
        historyRepository: HistoryRepository,
        authService: AuthService
    ) {
        self.medicineRepository = medicineRepository
        self.historyRepository = historyRepository
        self.authService = authService
        self.sessionViewModel = SessionViewModel(authService: authService)
    }

    @MainActor
    init() {
        self.init(
            medicineRepository: FirestoreMedicineRepository(),
            historyRepository: FirestoreHistoryRepository(),
            authService: FirebaseAuthService()
        )
    }
}
