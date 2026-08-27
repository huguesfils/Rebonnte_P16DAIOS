import Foundation
import Testing
@testable import MediStock

@MainActor
struct MedicineDetailViewModelTests {
    let mockMedicines = MockMedicineRepository()
    let mockHistory = MockHistoryRepository()
    let mockAuth = MockAuthService()

    private func makeStore() -> MedicineStore {
        MedicineStore(
            medicineRepository: mockMedicines,
            historyRepository: mockHistory,
            authService: mockAuth
        )
    }

    private func makeSUT(medicineId: String = "1") -> MedicineDetailViewModel {
        MedicineDetailViewModel(
            medicineId: medicineId,
            store: makeStore(),
            historyRepository: mockHistory
        )
    }

    private func makeLoadedSUT(
        _ medicines: [Medicine],
        medicineId: String = "1"
    ) async -> MedicineDetailViewModel {
        mockMedicines.storedMedicines = Dictionary(uniqueKeysWithValues: medicines.map { ($0.id, $0) })
        let store = makeStore()
        await store.loadIfNeeded()
        return MedicineDetailViewModel(
            medicineId: medicineId,
            store: store,
            historyRepository: mockHistory
        )
    }

    // MARK: - medicine (MEDI-9)

    @Test func medicineIsReadFromTheStore() async {
        let sut = await makeLoadedSUT([.stub(id: "1", name: "Doliprane")])

        #expect(sut.medicine?.name == "Doliprane")
    }

    @Test func medicineIsNilForAnUnknownId() async {
        let sut = await makeLoadedSUT([.stub(id: "1")], medicineId: "absent")

        #expect(sut.medicine == nil)
    }

    @Test func medicineReflectsAStockChangeWithoutAReload() async {
        let sut = await makeLoadedSUT([.stub(id: "1", stock: 10)])

        await sut.increaseStock()

        #expect(sut.medicine?.stock == 11)
        #expect(mockMedicines.fetchCallCount == 1)
    }

    @Test func medicineReflectsUpdatedDetailsWithoutAReload() async {
        let sut = await makeLoadedSUT([.stub(id: "1", name: "Doliprane")])

        await sut.updateDetails(name: "Efferalgan", aisle: "Rayon 2")

        #expect(sut.medicine?.name == "Efferalgan")
        #expect(mockMedicines.fetchCallCount == 1)
    }

    @Test func medicineBecomesNilAfterADelete() async {
        let sut = await makeLoadedSUT([.stub(id: "1")])

        let didDelete = await sut.delete()

        #expect(didDelete)
        #expect(sut.medicine == nil)
    }

    // MARK: - History refresh after a mutation

    @Test func aStockChangeRefreshesTheHistory() async {
        let sut = await makeLoadedSUT([.stub(id: "1", name: "Doliprane", stock: 10)])
        await sut.loadHistory()
        #expect(sut.history.isEmpty)

        await sut.increaseStock()

        #expect(sut.history.count == 1)
        #expect(sut.history.first?.action == "Stock de Doliprane augmenté de 1")
    }

    @Test func renamingRefreshesTheHistory() async {
        let sut = await makeLoadedSUT([.stub(id: "1", name: "Doliprane", aisle: "Rayon 1")])
        await sut.loadHistory()

        await sut.updateDetails(name: "Efferalgan", aisle: "Rayon 2")

        #expect(sut.history.first?.action == "Modification de Efferalgan")
    }

    @Test func aFailedMutationLeavesTheHistoryUntouched() async {
        let sut = await makeLoadedSUT([.stub(id: "1", stock: 10)])
        await sut.loadHistory()
        let fetchesSoFar = mockHistory.fetchCallCount
        mockMedicines.errorToThrow = MediStockError.networkUnavailable

        await sut.increaseStock()

        #expect(sut.history.isEmpty)
        #expect(mockHistory.fetchCallCount == fetchesSoFar)
    }

    // MARK: - History

    @Test func loadHistoryPublishesEntriesForMedicine() async {
        mockHistory.storedEntries = [
            .stub(id: "h1", medicineId: "1"),
            .stub(id: "h2", medicineId: "2")
        ]
        let sut = makeSUT()

        await sut.loadHistory()

        #expect(sut.history.map(\.id) == ["h1"])
    }

    @Test func loadHistoryFailureSurfacesError() async {
        mockHistory.errorToThrow = MediStockError.networkUnavailable
        let sut = makeSUT()

        await sut.loadHistory()

        #expect(sut.history.isEmpty)
        #expect(sut.errorMessage == MediStockError.networkUnavailable.localizedDescription)
    }

    @Test func historyLoadingFlagIsClearedAfterFailure() async {
        mockHistory.errorToThrow = MediStockError.networkUnavailable
        let sut = makeSUT()

        await sut.loadHistory()

        #expect(!sut.isLoadingHistory)
    }

    // MARK: - Error routing

    @Test func increaseStockSurfacesTheStoreError() async {
        let sut = await makeLoadedSUT([.stub(id: "1", stock: 10)])
        mockMedicines.errorToThrow = MediStockError.networkUnavailable

        await sut.increaseStock()

        #expect(sut.errorMessage == MediStockError.networkUnavailable.localizedDescription)
    }

    @Test func decreaseStockSurfacesTheStoreError() async {
        let sut = await makeLoadedSUT([.stub(id: "1", stock: 0)])

        await sut.decreaseStock()

        #expect(sut.errorMessage == MediStockError.negativeStock.localizedDescription)
    }

    @Test func setStockSurfacesTheStoreError() async {
        let sut = await makeLoadedSUT([.stub(id: "1", stock: 10)])
        mockMedicines.errorToThrow = MediStockError.networkUnavailable

        await sut.setStock(to: 42)

        #expect(sut.errorMessage == MediStockError.networkUnavailable.localizedDescription)
    }

    @Test func updateDetailsSurfacesTheStoreError() async {
        let sut = await makeLoadedSUT([.stub(id: "1")])
        mockMedicines.errorToThrow = MediStockError.permissionDenied

        await sut.updateDetails(name: "Renommé", aisle: "Rayon 1")

        #expect(sut.errorMessage == MediStockError.permissionDenied.localizedDescription)
    }

    @Test func updateDetailsOnBlankFieldsSurfacesInvalidData() async {
        let sut = await makeLoadedSUT([.stub(id: "1", name: "Doliprane")])

        await sut.updateDetails(name: "  ", aisle: "Rayon 1")

        #expect(sut.errorMessage == MediStockError.invalidData.localizedDescription)
        #expect(sut.medicine?.name == "Doliprane")
    }

    // MARK: - Successful mutations

    @Test func setStockAppliesTheAbsoluteValue() async {
        let sut = await makeLoadedSUT([.stub(id: "1", stock: 10)])

        await sut.setStock(to: 42)

        #expect(sut.medicine?.stock == 42)
        #expect(sut.errorMessage == nil)
    }

    // MARK: - Deletion

    @Test func deleteReturnsTrueOnSuccess() async {
        let sut = await makeLoadedSUT([.stub(id: "1")])

        let didDelete = await sut.delete()

        #expect(didDelete)
        #expect(sut.errorMessage == nil)
    }

    @Test func deleteReturnsFalseAndSurfacesErrorOnFailure() async {
        let sut = await makeLoadedSUT([.stub(id: "1")])
        mockMedicines.errorToThrow = MediStockError.permissionDenied

        let didDelete = await sut.delete()

        #expect(!didDelete)
        #expect(sut.errorMessage == MediStockError.permissionDenied.localizedDescription)
    }
}
