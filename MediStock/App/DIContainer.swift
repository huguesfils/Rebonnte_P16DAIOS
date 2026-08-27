import Foundation

struct DIContainer {
    let medicineRepository: MedicineRepository
    let historyRepository: HistoryRepository
    let authService: AuthService
    let networkMonitor: NetworkMonitor
    let sessionManager: SessionManager
    let medicineStore: MedicineStore
    let viewModelFactory: ViewModelFactory

    @MainActor
    init(
        medicineRepository: MedicineRepository,
        historyRepository: HistoryRepository,
        authService: AuthService,
        networkMonitor: NetworkMonitor
    ) {
        let guardedMedicineRepository = NetworkAwareMedicineRepository(
            wrapping: medicineRepository,
            networkMonitor: networkMonitor
        )
        let guardedHistoryRepository = NetworkAwareHistoryRepository(
            wrapping: historyRepository,
            networkMonitor: networkMonitor
        )

        self.medicineRepository = guardedMedicineRepository
        self.historyRepository = guardedHistoryRepository
        self.authService = authService
        self.networkMonitor = networkMonitor
        self.sessionManager = SessionManager(authService: authService)

        let medicineStore = MedicineStore(
            medicineRepository: guardedMedicineRepository,
            historyRepository: guardedHistoryRepository,
            authService: authService
        )
        self.medicineStore = medicineStore
        self.viewModelFactory = ViewModelFactory(
            historyRepository: guardedHistoryRepository,
            authService: authService,
            medicineStore: medicineStore
        )
    }

    @MainActor
    init() {
        self.init(
            medicineRepository: FirestoreMedicineRepository(),
            historyRepository: FirestoreHistoryRepository(),
            authService: FirebaseAuthService(),
            networkMonitor: NWPathNetworkMonitor()
        )
    }
}
