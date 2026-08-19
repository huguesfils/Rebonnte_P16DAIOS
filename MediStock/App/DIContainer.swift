import Foundation

struct DIContainer {
    let medicineRepository: MedicineRepository
    let historyRepository: HistoryRepository
    let authService: AuthService
    let sessionManager: SessionManager
    let medicineStore: MedicineStore
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

        let medicineStore = MedicineStore(
            medicineRepository: medicineRepository,
            historyRepository: historyRepository,
            authService: authService
        )
        self.medicineStore = medicineStore
        self.viewModelFactory = ViewModelFactory(
            historyRepository: historyRepository,
            authService: authService,
            medicineStore: medicineStore
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
