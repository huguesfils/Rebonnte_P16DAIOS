import Foundation
import Testing
@testable import MediStock

@MainActor
struct MedicineStockViewModelTests {
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

    // MARK: - Initial state

    @Test func initialStateIsEmpty() {
        let sut = makeSUT()
        #expect(sut.medicines.isEmpty)
        #expect(sut.history.isEmpty)
        #expect(sut.aisles.isEmpty)
        #expect(sut.errorMessage == nil)
    }

    // MARK: - loadMedicines

    @Test func loadMedicinesPublishesRepositoryContent() async {
        mockMedicines.storedMedicines = [
            "1": .stub(id: "1"),
            "2": .stub(id: "2", name: "Ibuprofène")
        ]
        let sut = makeSUT()

        await sut.loadMedicines()

        #expect(sut.medicines.count == 2)
        #expect(sut.errorMessage == nil)
    }

    @Test func loadMedicinesFailureSurfacesError() async {
        mockMedicines.errorToThrow = MediStockError.networkUnavailable
        let sut = makeSUT()

        await sut.loadMedicines()

        #expect(sut.medicines.isEmpty)
        #expect(sut.errorMessage == MediStockError.networkUnavailable.localizedDescription)
    }

    // MARK: - Loading state

    @Test func loadingFlagsAreClearedAfterSuccess() async {
        let sut = makeSUT()
        #expect(!sut.isLoadingMedicines)
        #expect(!sut.hasLoadedMedicines)

        await sut.loadMedicines()

        #expect(!sut.isLoadingMedicines)
        #expect(sut.hasLoadedMedicines)
    }

    @Test func loadingFlagsAreClearedAfterFailure() async {
        mockMedicines.errorToThrow = MediStockError.networkUnavailable
        let sut = makeSUT()

        await sut.loadMedicines()

        #expect(!sut.isLoadingMedicines)
        #expect(sut.hasLoadedMedicines)
    }

    @Test func historyLoadingFlagIsClearedAfterFailure() async {
        mockHistory.errorToThrow = MediStockError.networkUnavailable
        let sut = makeSUT()

        await sut.loadHistory(forMedicineId: "medicine-1")

        #expect(!sut.isLoadingHistory)
    }

    // MARK: - Chargement unique

    @Test func loadMedicinesIfNeededReadsOnlyOnce() async {
        let sut = makeSUT()

        await sut.loadMedicinesIfNeeded()
        await sut.loadMedicinesIfNeeded()
        await sut.loadMedicinesIfNeeded()

        #expect(mockMedicines.fetchCallCount == 1)
    }

    @Test func loadMedicinesIfNeededRetriesAfterAFailure() async {
        mockMedicines.errorToThrow = MediStockError.networkUnavailable
        let sut = makeSUT()
        await sut.loadMedicinesIfNeeded()

        mockMedicines.errorToThrow = nil
        mockMedicines.storedMedicines = ["1": .stub(id: "1")]
        await sut.loadMedicines()

        #expect(sut.medicines.count == 1)
    }

    @Test func explicitRefreshAlwaysReads() async {
        let sut = makeSUT()
        await sut.loadMedicinesIfNeeded()

        await sut.loadMedicines()

        #expect(mockMedicines.fetchCallCount == 2)
    }

    // MARK: - Derived state

    @Test func aislesAreDeduplicatedAndSorted() async {
        mockMedicines.storedMedicines = [
            "1": .stub(id: "1", aisle: "Aisle 2"),
            "2": .stub(id: "2", aisle: "Aisle 1"),
            "3": .stub(id: "3", aisle: "Aisle 2")
        ]
        let sut = makeSUT()

        await sut.loadMedicines()

        #expect(sut.aisles == ["Aisle 1", "Aisle 2"])
    }

    @Test func medicinesInAisleFiltersByAisle() async {
        mockMedicines.storedMedicines = [
            "1": .stub(id: "1", aisle: "Aisle 1"),
            "2": .stub(id: "2", aisle: "Aisle 2")
        ]
        let sut = makeSUT()
        await sut.loadMedicines()

        #expect(sut.medicines(inAisle: "Aisle 1").count == 1)
        #expect(sut.medicines(inAisle: "Aisle 9").isEmpty)
    }

    // MARK: - loadHistory

    @Test func loadHistoryPublishesEntriesForMedicine() async {
        mockHistory.storedEntries = [
            .stub(id: "h1", medicineId: "medicine-1"),
            .stub(id: "h2", medicineId: "other")
        ]
        let sut = makeSUT()

        await sut.loadHistory(forMedicineId: "medicine-1")

        #expect(sut.history.count == 1)
        #expect(sut.history.first?.id == "h1")
    }

    @Test func loadHistoryFailureSurfacesError() async {
        mockHistory.errorToThrow = MediStockError.networkUnavailable
        let sut = makeSUT()

        await sut.loadHistory(forMedicineId: "medicine-1")

        #expect(sut.history.isEmpty)
        #expect(sut.errorMessage == MediStockError.networkUnavailable.localizedDescription)
    }

    // MARK: - updateDetails

    @Test func updateDetailsSavesAndRecordsHistoryWithoutReload() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1")]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.updateDetails(medicineId: "1", name: "Renommé", aisle: "Aisle 1")

        #expect(sut.medicines.first?.name == "Renommé")
        #expect(mockHistory.addedEntries.count == 1)
        #expect(mockMedicines.fetchCallCount == 1)
    }

    @Test func updateDetailsFailureSurfacesError() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1")]
        let sut = makeSUT()
        await sut.loadMedicines()
        mockMedicines.errorToThrow = MediStockError.permissionDenied

        await sut.updateDetails(medicineId: "1", name: "Renommé", aisle: "Aisle 1")

        #expect(mockHistory.addedEntries.isEmpty)
        #expect(sut.errorMessage == MediStockError.permissionDenied.localizedDescription)
    }

    @Test func updateDetailsWithoutChangeWritesNothing() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", name: "Doliprane", aisle: "Aisle 1")]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.updateDetails(medicineId: "1", name: "Doliprane", aisle: "Aisle 1")

        #expect(mockMedicines.savedMedicines.isEmpty)
        #expect(mockHistory.addedEntries.isEmpty)
    }

    @Test("Renommer en valeur vide est refusé", arguments: [
        ("", "Aisle 1"),
        ("   ", "Aisle 1"),
        ("Doliprane", ""),
        ("Doliprane", "  ")
    ])
    func updateDetailsRejectsBlankFields(name: String, aisle: String) async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", name: "Doliprane", aisle: "Aisle 1")]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.updateDetails(medicineId: "1", name: name, aisle: aisle)

        #expect(mockMedicines.savedMedicines.isEmpty)
        #expect(mockHistory.addedEntries.isEmpty)
        #expect(sut.medicines.first?.name == "Doliprane")
        #expect(sut.errorMessage == MediStockError.invalidData.localizedDescription)
    }

    @Test func updateDetailsTrimsWhitespace() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", name: "Doliprane", aisle: "Aisle 1")]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.updateDetails(medicineId: "1", name: "  Efferalgan  ", aisle: " Aisle 2 ")

        #expect(sut.medicines.first?.name == "Efferalgan")
        #expect(sut.medicines.first?.aisle == "Aisle 2")
    }

    @Test func updateDetailsIgnoresChangeThatOnlyAddsWhitespace() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", name: "Doliprane", aisle: "Aisle 1")]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.updateDetails(medicineId: "1", name: "  Doliprane  ", aisle: "Aisle 1")

        #expect(mockMedicines.savedMedicines.isEmpty)
        #expect(mockHistory.addedEntries.isEmpty)
    }

    @Test func updateDetailsOnUnknownMedicineIsRejected() async {
        let sut = makeSUT()

        await sut.updateDetails(medicineId: "absent", name: "X", aisle: "Y")

        #expect(mockMedicines.savedMedicines.isEmpty)
        #expect(sut.errorMessage == MediStockError.medicineNotFound.localizedDescription)
    }

    // MARK: - History write failure

    @Test func successfulMutationIsKeptWhenHistoryWriteFails() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", stock: 10)]
        let sut = makeSUT()
        await sut.loadMedicines()
        mockHistory.errorToThrow = MediStockError.networkUnavailable

        await sut.increaseStock(medicineId: "1")

        #expect(sut.medicines.first?.stock == 11)
        #expect(sut.errorMessage == MediStockError.networkUnavailable.localizedDescription)
    }

    // MARK: - History entry content

    @Test func historyEntryCarriesAuthenticatedUserId() async {
        mockAuth.currentUser = AppUser(id: "user-42", email: "a@b.c")
        let sut = makeSUT()

        await sut.addMedicine(name: "Doliprane", stock: 1, aisle: "Aisle 3")

        #expect(mockHistory.addedEntries.first?.user == "user-42")
    }

    @Test func historyEntryCarriesAuthenticatedUserEmail() async {
        mockAuth.currentUser = AppUser(id: "user-42", email: "operateur@medistock.app")
        let sut = makeSUT()

        await sut.addMedicine(name: "Doliprane", stock: 1, aisle: "Aisle 3")

        let entry = mockHistory.addedEntries.first
        #expect(entry?.userEmail == "operateur@medistock.app")
        #expect(entry?.displayedUser == "operateur@medistock.app")
    }

    @Test func historyEntryFallsBackToIdWhenEmailIsMissing() async {
        mockAuth.currentUser = AppUser(id: "user-42", email: nil)
        let sut = makeSUT()

        await sut.addMedicine(name: "Doliprane", stock: 1, aisle: "Aisle 3")

        let entry = mockHistory.addedEntries.first
        #expect(entry?.userEmail == nil)
        #expect(entry?.displayedUser == "user-42")
    }

    @Test("Entrée existante sans email : repli sur l'identifiant", arguments: [nil, ""])
    func legacyEntriesFallBackToId(email: String?) {
        let entry = HistoryEntry.stub(user: "legacy-uid", userEmail: email)

        #expect(entry.displayedUser == "legacy-uid")
    }
}
