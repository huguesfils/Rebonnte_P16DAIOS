import Foundation
import Testing
@testable import MediStock

@MainActor
struct MedicineListViewModelTests {
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

    private func makeSUT() -> MedicineListViewModel {
        MedicineListViewModel(store: makeStore())
    }

    private func makeLoadedSUT(_ medicines: [Medicine]) async -> MedicineListViewModel {
        mockMedicines.storedMedicines = Dictionary(uniqueKeysWithValues: medicines.map { ($0.id, $0) })
        let store = makeStore()
        await store.loadIfNeeded()
        return MedicineListViewModel(store: store)
    }

    // MARK: - Sorting and filtering

    @Test func noSortPreservesStoreOrder() async {
        let sut = await makeLoadedSUT([
            .stub(id: "1", name: "Zyrtec"),
            .stub(id: "2", name: "Aspirine")
        ])

        #expect(sut.filteredAndSortedMedicines.map(\.name) == ["Zyrtec", "Aspirine"])
    }

    @Test func sortByNameIsCaseAndAccentInsensitive() async {
        let sut = await makeLoadedSUT([
            .stub(id: "1", name: "ibuprofène"),
            .stub(id: "2", name: "Aspirine"),
            .stub(id: "3", name: "Élixir")
        ])

        sut.sortOption = .name

        #expect(sut.filteredAndSortedMedicines.map(\.name) == ["Aspirine", "Élixir", "ibuprofène"])
    }

    @Test func sortByStockOrdersAscending() async {
        let sut = await makeLoadedSUT([
            .stub(id: "1", stock: 12),
            .stub(id: "2", stock: 3),
            .stub(id: "3", stock: 7)
        ])

        sut.sortOption = .stock

        #expect(sut.filteredAndSortedMedicines.map(\.stock) == [3, 7, 12])
    }

    @Test func filterIsCaseInsensitive() async {
        let sut = await makeLoadedSUT([
            .stub(id: "1", name: "Doliprane"),
            .stub(id: "2", name: "Aspirine")
        ])

        sut.filterText = "dolI"

        #expect(sut.filteredAndSortedMedicines.map(\.name) == ["Doliprane"])
    }

    @Test func filterAndSortCombine() async {
        let sut = await makeLoadedSUT([
            .stub(id: "1", name: "Doliprane 500", stock: 12),
            .stub(id: "2", name: "Doliprane 1000", stock: 3),
            .stub(id: "3", name: "Aspirine", stock: 1)
        ])

        sut.filterText = "doliprane"
        sut.sortOption = .stock

        #expect(sut.filteredAndSortedMedicines.map(\.stock) == [3, 12])
    }

    @Test func filterWithoutMatchReturnsAnEmptyList() async {
        let sut = await makeLoadedSUT([.stub(id: "1", name: "Doliprane")])

        sut.filterText = "absent"

        #expect(sut.filteredAndSortedMedicines.isEmpty)
    }

    @Test func emptyStoreReturnsAnEmptyList() {
        let sut = makeSUT()

        #expect(sut.filteredAndSortedMedicines.isEmpty)
    }

    // MARK: - State

    @Test func isStockEmptyReflectsTheStore() async {
        let sut = makeSUT()
        #expect(sut.isStockEmpty)

        let loaded = await makeLoadedSUT([.stub(id: "1")])

        #expect(!loaded.isStockEmpty)
    }

    @Test func isLoadingIsClearedAfterTheLoad() async {
        let sut = await makeLoadedSUT([.stub(id: "1")])

        #expect(!sut.isLoading)
    }

    @Test func filteredAndSortedMedicinesReflectAStockChange() async {
        mockMedicines.storedMedicines = [
            "1": .stub(id: "1", stock: 1),
            "2": .stub(id: "2", stock: 5)
        ]
        let store = makeStore()
        await store.loadIfNeeded()
        let sut = MedicineListViewModel(store: store)
        sut.sortOption = .stock
        #expect(sut.filteredAndSortedMedicines.map(\.id) == ["1", "2"])

        try? await store.setStock(medicineId: "1", to: 9)

        #expect(sut.filteredAndSortedMedicines.map(\.id) == ["2", "1"])
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

    // MARK: - Swipe to delete

    @Test func deleteAtOffsetsRemovesTheSwipedRows() async {
        let sut = await makeLoadedSUT([
            .stub(id: "1"),
            .stub(id: "2"),
            .stub(id: "3")
        ])

        await sut.delete(atOffsets: IndexSet([0, 2]))

        #expect(Set(mockMedicines.deletedIds) == ["1", "3"])
        #expect(sut.filteredAndSortedMedicines.map(\.id) == ["2"])
    }

    @Test func deleteAtOffsetsMapsAgainstTheDisplayedOrder() async {
        let sut = await makeLoadedSUT([
            .stub(id: "1", name: "Zyrtec"),
            .stub(id: "2", name: "Aspirine")
        ])
        sut.sortOption = .name

        await sut.delete(atOffsets: IndexSet([0]))

        #expect(mockMedicines.deletedIds == ["2"])
    }

    @Test func deleteAtOffsetsIgnoresOutOfBoundsIndexes() async {
        let sut = await makeLoadedSUT([.stub(id: "1")])

        await sut.delete(atOffsets: IndexSet([5]))

        #expect(mockMedicines.deletedIds.isEmpty)
    }

    @Test func deleteAtOffsetsFailureSurfacesErrorMessage() async {
        let sut = await makeLoadedSUT([.stub(id: "1")])
        mockMedicines.errorToThrow = MediStockError.permissionDenied

        await sut.delete(atOffsets: IndexSet([0]))

        #expect(sut.errorMessage == MediStockError.permissionDenied.localizedDescription)
    }
}
