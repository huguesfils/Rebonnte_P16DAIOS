import Foundation

struct DIContainer {
    let medicineRepository: MedicineRepository
    let historyRepository: HistoryRepository
    let authService: AuthService
    let sessionManager: SessionManager
    let viewModelFactory: ViewModelFactory

    @MainActor
    init(
        medicineRepository: MedicineRepository,
        historyRepository: HistoryRepository,
        authService: AuthService
    ) {
        self.medicineRepository = medicineRepository
        self.historyRepository = historyRepository
        self.authService = authService
        self.sessionManager = SessionManager(authService: authService)
        self.viewModelFactory = ViewModelFactory(
            medicineRepository: medicineRepository,
            historyRepository: historyRepository,
            authService: authService
        )
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
