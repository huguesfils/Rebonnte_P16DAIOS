import Foundation

struct ViewModelFactory {
    private let historyRepository: HistoryRepository
    private let authService: AuthService
    private let medicineStore: MedicineStore

    init(
        historyRepository: HistoryRepository,
        authService: AuthService,
        medicineStore: MedicineStore
    ) {
        self.historyRepository = historyRepository
        self.authService = authService
        self.medicineStore = medicineStore
    }

    // MARK: - Auth

    @MainActor
    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(authService: authService)
    }

    @MainActor
    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(authService: authService, appInfo: AppInfo(bundle: .main))
    }

    // MARK: - Aisles

    @MainActor
    func makeAisleListViewModel() -> AisleListViewModel {
        AisleListViewModel(store: medicineStore)
    }

    @MainActor
    func makeAisleMedicinesViewModel(aisle: String) -> AisleMedicinesViewModel {
        AisleMedicinesViewModel(aisle: aisle, store: medicineStore)
    }

    // MARK: - Medicines

    @MainActor
    func makeMedicineListViewModel() -> MedicineListViewModel {
        MedicineListViewModel(store: medicineStore)
    }

    @MainActor
    func makeMedicineDetailViewModel(medicineId: String) -> MedicineDetailViewModel {
        MedicineDetailViewModel(
            medicineId: medicineId,
            store: medicineStore,
            historyRepository: historyRepository
        )
    }

    @MainActor
    func makeAddMedicineViewModel() -> AddMedicineViewModel {
        AddMedicineViewModel(store: medicineStore)
    }
}
