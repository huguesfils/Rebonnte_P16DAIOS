import Foundation
import Testing
@testable import MediStock

@MainActor
struct AisleMedicinesViewModelTests {
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

    private func makeLoadedSUT(
        _ medicines: [Medicine],
        aisle: String = "Rayon 1"
    ) async -> AisleMedicinesViewModel {
        mockMedicines.storedMedicines = Dictionary(uniqueKeysWithValues: medicines.map { ($0.id, $0) })
        let store = makeStore()
        await store.loadIfNeeded()
        return AisleMedicinesViewModel(aisle: aisle, store: store)
    }

    // MARK: - Derivation

    @Test func medicinesInAisleFiltersByAisle() async {
        let sut = await makeLoadedSUT([
            .stub(id: "1", aisle: "Rayon 1"),
            .stub(id: "2", aisle: "Rayon 2")
        ])

        #expect(sut.medicines.map(\.id) == ["1"])
    }

    @Test func medicinesAreEmptyForAnUnknownAisle() async {
        let sut = await makeLoadedSUT([.stub(id: "1", aisle: "Rayon 1")], aisle: "Rayon 42")

        #expect(sut.medicines.isEmpty)
    }

    @Test func medicinesReflectAStockChangeAppliedByTheStore() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", stock: 10, aisle: "Rayon 1")]
        let store = makeStore()
        await store.loadIfNeeded()
        let sut = AisleMedicinesViewModel(aisle: "Rayon 1", store: store)

        try? await store.adjustStock(medicineId: "1", by: 1)

        #expect(sut.medicines.first?.stock == 11)
    }

    // MARK: - Swipe to delete

    @Test func deleteAtOffsetsRemovesTheSwipedRowsOfThisAisleOnly() async {
        let sut = await makeLoadedSUT([
            .stub(id: "1", aisle: "Rayon 1"),
            .stub(id: "2", aisle: "Rayon 2"),
            .stub(id: "3", aisle: "Rayon 1")
        ])

        await sut.delete(atOffsets: IndexSet([1]))

        #expect(mockMedicines.deletedIds == ["3"])
    }

    @Test func deleteAtOffsetsIgnoresOutOfBoundsIndexes() async {
        let sut = await makeLoadedSUT([.stub(id: "1", aisle: "Rayon 1")])

        await sut.delete(atOffsets: IndexSet([5]))

        #expect(mockMedicines.deletedIds.isEmpty)
    }

    @Test func deleteAtOffsetsFailureSurfacesErrorMessage() async {
        let sut = await makeLoadedSUT([.stub(id: "1", aisle: "Rayon 1")])
        mockMedicines.errorToThrow = MediStockError.permissionDenied

        await sut.delete(atOffsets: IndexSet([0]))

        #expect(sut.errorMessage == MediStockError.permissionDenied.localizedDescription)
    }

    // MARK: - Errors

    @Test func refreshRelaysTheStoreLoadError() async {
        let sut = await makeLoadedSUT([.stub(id: "1", aisle: "Rayon 1")])
        mockMedicines.errorToThrow = MediStockError.networkUnavailable

        await sut.refresh()

        #expect(sut.errorMessage == MediStockError.networkUnavailable.localizedDescription)
    }
}
