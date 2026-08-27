import Foundation
import Testing
@testable import MediStock

@MainActor
struct AddMedicineViewModelOfflineTests {
    let mockMedicines = MockMedicineRepository()
    let mockHistory = MockHistoryRepository()
    let mockAuth = MockAuthService()
    let monitor = MockNetworkMonitor(isConnected: false)

    private func makeSUT() -> AddMedicineViewModel {
        let viewModel = AddMedicineViewModel(
            store: MedicineStore(
                medicineRepository: NetworkAwareMedicineRepository(
                    wrapping: mockMedicines,
                    networkMonitor: monitor
                ),
                historyRepository: NetworkAwareHistoryRepository(
                    wrapping: mockHistory,
                    networkMonitor: monitor
                ),
                authService: mockAuth
            )
        )
        viewModel.name = "Doliprane"
        viewModel.aisle = "Rayon 1"
        viewModel.stock = 12
        return viewModel
    }

    // MARK: - Hors-ligne

    @Test func offlineSaveClearsTheSavingFlag() async {
        let sut = makeSUT()

        let saved = await sut.save()

        #expect(!saved)
        #expect(!sut.isSaving)
        #expect(sut.errorMessage == MediStockError.networkUnavailable.localizedDescription)
    }

    @Test func offlineSaveWritesNothing() async {
        let sut = makeSUT()

        _ = await sut.save()

        #expect(mockMedicines.savedMedicines.isEmpty)
        #expect(mockHistory.addedEntries.isEmpty)
        #expect(mockMedicines.fetchCallCount == 0)
    }

    // MARK: - Retour du réseau

    @Test func connectedSaveStillWorksThroughTheDecorators() async {
        monitor.isConnected = true
        let sut = makeSUT()

        let saved = await sut.save()

        #expect(saved)
        #expect(mockMedicines.savedMedicines.count == 1)
        #expect(mockHistory.addedEntries.count == 1)
    }
}
