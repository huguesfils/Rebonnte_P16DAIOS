import Foundation
@testable import MediStock

@MainActor
struct IntegrationTestApp {
    let fakeMedicines: MockMedicineRepository
    let fakeHistory: MockHistoryRepository
    let fakeAuth: MockAuthService
    let fakeNetwork: MockNetworkMonitor
    let container: DIContainer

    init(medicines: [Medicine] = [], isConnected: Bool = true) {
        let fakeMedicines = MockMedicineRepository(medicines: medicines)
        let fakeHistory = MockHistoryRepository()
        let fakeAuth = MockAuthService()
        let fakeNetwork = MockNetworkMonitor(isConnected: isConnected)

        self.fakeMedicines = fakeMedicines
        self.fakeHistory = fakeHistory
        self.fakeAuth = fakeAuth
        self.fakeNetwork = fakeNetwork
        self.container = DIContainer(
            medicineRepository: fakeMedicines,
            historyRepository: fakeHistory,
            authService: fakeAuth,
            networkMonitor: fakeNetwork
        )
    }
}
