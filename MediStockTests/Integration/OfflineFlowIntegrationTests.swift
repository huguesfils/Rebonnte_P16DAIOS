import Foundation
import Testing
@testable import MediStock

@MainActor
struct OfflineFlowIntegrationTests {
    private func makeSUT(medicines: [Medicine] = [], isConnected: Bool = false) -> IntegrationTestApp {
        IntegrationTestApp(medicines: medicines, isConnected: isConnected)
    }

    // MARK: - Écriture hors-ligne

    @Test func savingOfflineIsRejectedBeforeAnyRepositoryCall() async {
        let app = makeSUT()
        let add = app.container.viewModelFactory.makeAddMedicineViewModel()
        add.name = "Doliprane"
        add.aisle = "Rayon 1"
        add.stock = 12

        let didSave = await add.save()

        #expect(!didSave)
        #expect(add.errorMessage == MediStockError.networkUnavailable.localizedDescription)
        #expect(!add.isSaving)
        #expect(app.fakeMedicines.savedMedicines.isEmpty)
        #expect(app.fakeMedicines.fetchCallCount == 0)
        #expect(app.fakeHistory.addedEntries.isEmpty)
        #expect(app.container.medicineStore.medicines.isEmpty)
    }

    // MARK: - Lecture hors-ligne hors du store

    @Test func historyReadThroughTheFactoryIsGuardedOffline() async {
        let seeded = Medicine.stub()
        let app = makeSUT(medicines: [seeded])
        let detail = app.container.viewModelFactory.makeMedicineDetailViewModel(medicineId: seeded.id)

        await detail.loadHistory()

        #expect(detail.history.isEmpty)
        #expect(detail.errorMessage == MediStockError.networkUnavailable.localizedDescription)
        #expect(app.fakeHistory.fetchCallCount == 0)
        #expect(!detail.isLoadingHistory)
    }
}
