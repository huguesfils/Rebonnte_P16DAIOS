import Foundation
import Testing
@testable import MediStock

@MainActor
struct MedicineDeletionTests {
    let mockMedicines = MockMedicineRepository()
    let mockHistory = MockHistoryRepository()
    let mockAuth = MockAuthService()

    private func makeSUT() -> MedicineStockViewModel {
        MedicineStockViewModel(
            medicineRepository: mockMedicines,
            historyRepository: mockHistory,
            authService: mockAuth
        )
    }

    // MARK: - delete

    @Test func deleteRemovesMedicineAndReloads() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", name: "Doliprane", stock: 7, aisle: "Rayon 2")]
        let sut = makeSUT()
        await sut.loadMedicines()

        let didDelete = await sut.delete(medicineId: "1")

        #expect(didDelete)
        #expect(mockMedicines.deletedIds == ["1"])
        #expect(sut.medicines.isEmpty)
        #expect(mockHistory.addedEntries.first?.action == "Suppression de Doliprane")
        #expect(mockHistory.addedEntries.first?.details == "Retiré de Rayon 2, stock de 7")
    }

    @Test func deleteFailureSurfacesErrorAndKeepsMedicine() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1")]
        let sut = makeSUT()
        await sut.loadMedicines()
        mockMedicines.errorToThrow = MediStockError.permissionDenied

        let didDelete = await sut.delete(medicineId: "1")

        #expect(!didDelete)
        #expect(mockMedicines.deletedIds.isEmpty)
        #expect(sut.medicines.count == 1)
        #expect(mockHistory.addedEntries.isEmpty)
        #expect(sut.errorMessage == MediStockError.permissionDenied.localizedDescription)
    }

    @Test func deleteUnknownMedicineIsRejected() async {
        let sut = makeSUT()

        let didDelete = await sut.delete(medicineId: "absent")

        #expect(!didDelete)
        #expect(mockMedicines.deletedIds.isEmpty)
        #expect(sut.errorMessage == MediStockError.medicineNotFound.localizedDescription)
    }

    @Test func deleteWithoutUserIsRejected() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1")]
        let sut = makeSUT()
        await sut.loadMedicines()
        mockAuth.currentUser = nil

        let didDelete = await sut.delete(medicineId: "1")

        #expect(!didDelete)
        #expect(mockMedicines.deletedIds.isEmpty)
        #expect(sut.errorMessage == MediStockError.notAuthenticated.localizedDescription)
    }

    // MARK: - Swipe to delete

    @Test func deleteAtOffsetsRemovesTheSwipedRows() async {
        mockMedicines.storedMedicines = [
            "1": .stub(id: "1"),
            "2": .stub(id: "2"),
            "3": .stub(id: "3")
        ]
        let sut = makeSUT()
        await sut.loadMedicines()
        let displayed = sut.medicines

        await sut.delete(atOffsets: IndexSet([0, 2]), in: displayed)

        #expect(Set(mockMedicines.deletedIds) == ["1", "3"])
        #expect(sut.medicines.map(\.id) == ["2"])
    }

    @Test func deleteAtOffsetsMapsAgainstTheDisplayedOrder() async {
        mockMedicines.storedMedicines = [
            "1": .stub(id: "1", name: "Zyrtec"),
            "2": .stub(id: "2", name: "Aspirine")
        ]
        let sut = makeSUT()
        await sut.loadMedicines()
        let displayed = sut.medicines.sorted { $0.name < $1.name }

        await sut.delete(atOffsets: IndexSet([0]), in: displayed)

        #expect(mockMedicines.deletedIds == ["2"])
    }

    @Test func deleteAtOffsetsIgnoresOutOfBoundsIndexes() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1")]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.delete(atOffsets: IndexSet([5]), in: sut.medicines)

        #expect(mockMedicines.deletedIds.isEmpty)
        #expect(sut.medicines.count == 1)
    }
}
