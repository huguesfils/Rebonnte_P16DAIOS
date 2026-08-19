import Foundation
import Testing
@testable import MediStock

@MainActor
struct MedicineStoreMutationTests {
    let mockMedicines = MockMedicineRepository()
    let mockHistory = MockHistoryRepository()
    let mockAuth = MockAuthService()

    private func makeSUT() -> MedicineStore {
        MedicineStore(
            medicineRepository: mockMedicines,
            historyRepository: mockHistory,
            authService: mockAuth
        )
    }

    private func makeLoadedSUT(_ medicines: [Medicine]) async -> MedicineStore {
        mockMedicines.storedMedicines = Dictionary(uniqueKeysWithValues: medicines.map { ($0.id, $0) })
        let sut = makeSUT()
        await sut.loadIfNeeded()
        return sut
    }

    // MARK: - Stock

    @Test func adjustStockAppliesOptimisticUpdateWithoutReload() async throws {
        let sut = await makeLoadedSUT([.stub(id: "1", stock: 10)])

        try await sut.adjustStock(medicineId: "1", by: 1)

        #expect(sut.medicines.first?.stock == 11)
        #expect(mockMedicines.updatedStocks.first?.newStock == 11)
        #expect(mockMedicines.fetchCallCount == 1)
    }

    @Test func decreaseStockAppliesOptimisticUpdate() async throws {
        let sut = await makeLoadedSUT([.stub(id: "1", stock: 10)])

        try await sut.adjustStock(medicineId: "1", by: -1)

        #expect(sut.medicines.first?.stock == 9)
    }

    @Test func stockUpdateFailureKeepsPreviousValue() async {
        let sut = await makeLoadedSUT([.stub(id: "1", stock: 10)])
        mockMedicines.errorToThrow = MediStockError.networkUnavailable

        await #expect(throws: MediStockError.networkUnavailable) {
            try await sut.adjustStock(medicineId: "1", by: 1)
        }

        #expect(sut.medicines.first?.stock == 10)
    }

    @Test func stockUpdateWithoutUserIsRejected() async {
        let sut = await makeLoadedSUT([.stub(id: "1", stock: 10)])
        mockAuth.currentUser = nil

        await #expect(throws: MediStockError.notAuthenticated) {
            try await sut.adjustStock(medicineId: "1", by: 1)
        }

        #expect(mockMedicines.updatedStocks.isEmpty)
    }

    @Test func repeatedIncrementsAccumulate() async throws {
        let sut = await makeLoadedSUT([.stub(id: "1", stock: 10)])

        try await sut.adjustStock(medicineId: "1", by: 1)
        try await sut.adjustStock(medicineId: "1", by: 1)

        #expect(sut.medicines.first?.stock == 12)
    }

    @Test func repeatedDecrementsAccumulate() async throws {
        let sut = await makeLoadedSUT([.stub(id: "1", stock: 10)])

        try await sut.adjustStock(medicineId: "1", by: -1)
        try await sut.adjustStock(medicineId: "1", by: -1)

        #expect(sut.medicines.first?.stock == 8)
    }

    @Test func historyDetailsReflectEachTransition() async throws {
        let sut = await makeLoadedSUT([.stub(id: "1", stock: 10)])

        try await sut.adjustStock(medicineId: "1", by: 1)
        try await sut.adjustStock(medicineId: "1", by: 1)

        #expect(mockHistory.addedEntries.map(\.details) == [
            "Stock passé de 10 à 11",
            "Stock passé de 11 à 12"
        ])
    }

    @Test func stockUpdateOnUnknownMedicineIsRejected() async {
        let sut = makeSUT()

        await #expect(throws: MediStockError.medicineNotFound) {
            try await sut.adjustStock(medicineId: "absent", by: 1)
        }

        #expect(mockMedicines.updatedStocks.isEmpty)
    }

    @Test func adjustmentIsRelativeSoAConcurrentChangeIsNotLost() async throws {
        let sut = await makeLoadedSUT([.stub(id: "1", stock: 10)])
        mockMedicines.storedMedicines["1"]?.stock = 20

        try await sut.adjustStock(medicineId: "1", by: 1)

        #expect(mockMedicines.storedMedicines["1"]?.stock == 21)
        #expect(sut.medicines.first?.stock == 21)
        #expect(mockHistory.addedEntries.first?.details == "Stock passé de 20 à 21")
    }

    @Test func stockCannotGoNegative() async {
        let sut = await makeLoadedSUT([.stub(id: "1", stock: 0)])

        await #expect(throws: MediStockError.negativeStock) {
            try await sut.adjustStock(medicineId: "1", by: -1)
        }

        #expect(sut.medicines.first?.stock == 0)
        #expect(mockHistory.addedEntries.isEmpty)
    }

    @Test func setStockAppliesAbsoluteValue() async throws {
        let sut = await makeLoadedSUT([.stub(id: "1", stock: 10)])

        try await sut.setStock(medicineId: "1", to: 42)

        #expect(sut.medicines.first?.stock == 42)
        #expect(mockHistory.addedEntries.first?.details == "Stock passé de 10 à 42")
    }

    @Test func setStockToSameValueWritesNothing() async throws {
        let sut = await makeLoadedSUT([.stub(id: "1", stock: 10)])

        try await sut.setStock(medicineId: "1", to: 10)

        #expect(mockMedicines.updatedStocks.isEmpty)
        #expect(mockHistory.addedEntries.isEmpty)
    }

    @Test func successfulMutationIsKeptWhenHistoryWriteFails() async {
        let sut = await makeLoadedSUT([.stub(id: "1", stock: 10)])
        mockHistory.errorToThrow = MediStockError.networkUnavailable

        await #expect(throws: MediStockError.networkUnavailable) {
            try await sut.adjustStock(medicineId: "1", by: 1)
        }

        #expect(sut.medicines.first?.stock == 11)
    }

    // MARK: - updateDetails

    @Test func updateDetailsSavesAndRecordsHistoryWithoutReload() async throws {
        let sut = await makeLoadedSUT([.stub(id: "1", name: "Doliprane", aisle: "Rayon 1")])

        try await sut.updateDetails(medicineId: "1", name: "Efferalgan", aisle: "Rayon 2")

        #expect(sut.medicines.first?.name == "Efferalgan")
        #expect(sut.medicines.first?.aisle == "Rayon 2")
        #expect(mockHistory.addedEntries.count == 1)
        #expect(mockMedicines.fetchCallCount == 1)
    }

    @Test func updateDetailsFailureThrowsAndSkipsHistory() async {
        let sut = await makeLoadedSUT([.stub(id: "1")])
        mockMedicines.errorToThrow = MediStockError.permissionDenied

        await #expect(throws: MediStockError.permissionDenied) {
            try await sut.updateDetails(medicineId: "1", name: "Renommé", aisle: "Rayon 1")
        }

        #expect(mockHistory.addedEntries.isEmpty)
    }

    @Test func updateDetailsWithoutChangeWritesNothing() async throws {
        let sut = await makeLoadedSUT([.stub(id: "1", name: "Doliprane", aisle: "Rayon 1")])

        try await sut.updateDetails(medicineId: "1", name: "Doliprane", aisle: "Rayon 1")

        #expect(mockMedicines.savedMedicines.isEmpty)
        #expect(mockHistory.addedEntries.isEmpty)
    }

    @Test(arguments: [
        ("", "Rayon 1"),
        ("   ", "Rayon 1"),
        ("Doliprane", ""),
        ("Doliprane", "  ")
    ])
    func updateDetailsRejectsBlankFields(name: String, aisle: String) async {
        let sut = await makeLoadedSUT([.stub(id: "1", name: "Doliprane", aisle: "Rayon 1")])

        await #expect(throws: MediStockError.invalidData) {
            try await sut.updateDetails(medicineId: "1", name: name, aisle: aisle)
        }

        #expect(sut.medicines.first?.name == "Doliprane")
    }

    @Test func updateDetailsTrimsWhitespace() async throws {
        let sut = await makeLoadedSUT([.stub(id: "1", name: "Doliprane", aisle: "Rayon 1")])

        try await sut.updateDetails(medicineId: "1", name: "  Efferalgan  ", aisle: " Rayon 2 ")

        #expect(sut.medicines.first?.name == "Efferalgan")
        #expect(sut.medicines.first?.aisle == "Rayon 2")
    }

    @Test func updateDetailsIgnoresChangeThatOnlyAddsWhitespace() async throws {
        let sut = await makeLoadedSUT([.stub(id: "1", name: "Doliprane", aisle: "Rayon 1")])

        try await sut.updateDetails(medicineId: "1", name: "  Doliprane  ", aisle: "Rayon 1")

        #expect(mockMedicines.savedMedicines.isEmpty)
        #expect(mockHistory.addedEntries.isEmpty)
    }

    @Test func updateDetailsOnUnknownMedicineIsRejected() async {
        let sut = makeSUT()

        await #expect(throws: MediStockError.medicineNotFound) {
            try await sut.updateDetails(medicineId: "absent", name: "Renommé", aisle: "Rayon 1")
        }
    }

    @Test func updateDetailsWithoutUserIsRejected() async {
        let sut = await makeLoadedSUT([.stub(id: "1")])
        mockAuth.currentUser = nil

        await #expect(throws: MediStockError.notAuthenticated) {
            try await sut.updateDetails(medicineId: "1", name: "Renommé", aisle: "Rayon 1")
        }

        #expect(mockMedicines.savedMedicines.isEmpty)
    }

    // MARK: - addMedicine

    @Test func addMedicineRecordsHistoryAndReloads() async throws {
        let sut = makeSUT()

        try await sut.addMedicine(name: "Doliprane", stock: 12, aisle: "Rayon 3")

        #expect(mockHistory.addedEntries.count == 1)
        #expect(mockHistory.addedEntries.first?.action == "Ajout de Doliprane")
        #expect(mockHistory.addedEntries.first?.details == "Créé avec un stock de 12 dans Rayon 3")
        #expect(mockMedicines.fetchCallCount == 1)
        #expect(sut.medicines.count == 1)
    }

    @Test func addMedicineReloadsEvenWhenTheHistoryWriteFails() async {
        let sut = makeSUT()
        mockHistory.errorToThrow = MediStockError.networkUnavailable

        await #expect(throws: MediStockError.networkUnavailable) {
            try await sut.addMedicine(name: "Doliprane", stock: 12, aisle: "Rayon 3")
        }

        #expect(mockMedicines.fetchCallCount == 1)
        #expect(sut.medicines.count == 1)
    }

    // MARK: - delete

    @Test func deleteRemovesMedicineAndReloads() async throws {
        let sut = await makeLoadedSUT([.stub(id: "1", name: "Doliprane", stock: 7, aisle: "Rayon 2")])

        try await sut.delete(medicineId: "1")

        #expect(mockMedicines.deletedIds == ["1"])
        #expect(sut.medicines.isEmpty)
        #expect(mockHistory.addedEntries.first?.action == "Suppression de Doliprane")
        #expect(mockHistory.addedEntries.first?.details == "Retiré de Rayon 2, stock de 7")
    }

    @Test func deleteFailureThrowsAndKeepsMedicine() async {
        let sut = await makeLoadedSUT([.stub(id: "1")])
        mockMedicines.errorToThrow = MediStockError.permissionDenied

        await #expect(throws: MediStockError.permissionDenied) {
            try await sut.delete(medicineId: "1")
        }

        #expect(sut.medicines.count == 1)
        #expect(mockHistory.addedEntries.isEmpty)
    }

    @Test func deleteUnknownMedicineIsRejected() async {
        let sut = makeSUT()

        await #expect(throws: MediStockError.medicineNotFound) {
            try await sut.delete(medicineId: "absent")
        }
    }

    @Test func deleteWithoutUserIsRejected() async {
        let sut = await makeLoadedSUT([.stub(id: "1")])
        mockAuth.currentUser = nil

        await #expect(throws: MediStockError.notAuthenticated) {
            try await sut.delete(medicineId: "1")
        }

        #expect(mockMedicines.deletedIds.isEmpty)
    }

    // MARK: - History attribution

    @Test func historyEntryCarriesAuthenticatedUserId() async throws {
        let sut = await makeLoadedSUT([.stub(id: "1", stock: 10)])

        try await sut.adjustStock(medicineId: "1", by: 1)

        #expect(mockHistory.addedEntries.first?.user == "test-user")
    }

    @Test func historyEntryCarriesAuthenticatedUserEmail() async throws {
        let sut = await makeLoadedSUT([.stub(id: "1", stock: 10)])

        try await sut.adjustStock(medicineId: "1", by: 1)

        #expect(mockHistory.addedEntries.first?.userEmail == "test@medistock.app")
    }

    @Test func historyEntryFallsBackToIdWhenEmailIsMissing() async throws {
        let sut = await makeLoadedSUT([.stub(id: "1", stock: 10)])
        mockAuth.currentUser = AppUser(id: "test-user", email: nil)

        try await sut.adjustStock(medicineId: "1", by: 1)

        #expect(mockHistory.addedEntries.first?.displayedUser == "test-user")
    }
}
