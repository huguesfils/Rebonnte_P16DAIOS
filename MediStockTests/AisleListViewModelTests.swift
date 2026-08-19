import Foundation
import Testing
@testable import MediStock

@MainActor
struct AisleListViewModelTests {
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

    private func makeSUT() -> AisleListViewModel {
        AisleListViewModel(store: makeStore())
    }

    private func makeLoadedSUT(_ medicines: [Medicine]) async -> AisleListViewModel {
        mockMedicines.storedMedicines = Dictionary(uniqueKeysWithValues: medicines.map { ($0.id, $0) })
        let store = makeStore()
        await store.loadIfNeeded()
        return AisleListViewModel(store: store)
    }

    // MARK: - Derivation

    @Test func aislesAreDeduplicatedAndSorted() async {
        let sut = await makeLoadedSUT([
            .stub(id: "1", aisle: "Rayon 2"),
            .stub(id: "2", aisle: "Rayon 1"),
            .stub(id: "3", aisle: "Rayon 2")
        ])

        #expect(sut.aisles == ["Rayon 1", "Rayon 2"])
    }

    @Test func aislesAreEmptyWhenTheStoreIsEmpty() {
        let sut = makeSUT()

        #expect(sut.aisles.isEmpty)
    }

    @Test func aislesReflectAMedicineAddedAfterTheInitialLoad() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", aisle: "Rayon 1")]
        let store = makeStore()
        await store.loadIfNeeded()
        let sut = AisleListViewModel(store: store)
        #expect(sut.aisles == ["Rayon 1"])

        try? await store.addMedicine(name: "Aspirine", stock: 3, aisle: "Rayon 9")

        #expect(sut.aisles == ["Rayon 1", "Rayon 9"])
    }

    // MARK: - State

    @Test func isLoadingIsClearedAfterTheLoad() async {
        let sut = await makeLoadedSUT([.stub(id: "1")])

        #expect(!sut.isLoading)
    }

    // MARK: - Loading and errors

    @Test func loadIfNeededRelaysTheStoreLoadError() async {
        mockMedicines.errorToThrow = MediStockError.networkUnavailable
        let sut = makeSUT()

        await sut.loadIfNeeded()

        #expect(sut.errorMessage == MediStockError.networkUnavailable.localizedDescription)
    }

    @Test func loadIfNeededLeavesNoErrorOnSuccess() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1")]
        let sut = makeSUT()

        await sut.loadIfNeeded()

        #expect(sut.errorMessage == nil)
    }

    @Test func refreshRelaysTheStoreLoadError() async {
        let sut = makeSUT()
        mockMedicines.errorToThrow = MediStockError.networkUnavailable

        await sut.refresh()

        #expect(sut.errorMessage == MediStockError.networkUnavailable.localizedDescription)
    }
}
