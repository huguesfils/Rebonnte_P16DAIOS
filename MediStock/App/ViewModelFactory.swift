import Foundation

struct ViewModelFactory {
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

    // MARK: - Auth

    @MainActor
    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(authService: authService)
    }

    // MARK: - Medicines

    @MainActor
    func makeMedicineStockViewModel() -> MedicineStockViewModel {
        MedicineStockViewModel(
            medicineRepository: medicineRepository,
            historyRepository: historyRepository,
            authService: authService
        )
    }
}
