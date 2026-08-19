import Foundation
import Testing
@testable import MediStock

@MainActor
struct MedicineStoreTests {
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

    // MARK: - Initial state

    @Test func initialStateIsEmpty() {
        let sut = makeSUT()

        #expect(sut.medicines.isEmpty)
        #expect(!sut.isLoading)
        #expect(sut.loadedForUserId == nil)
        #expect(sut.loadError == nil)
    }

    // MARK: - Reading

    @Test func refreshPublishesRepositoryContent() async {
        mockMedicines.storedMedicines = [
            "1": .stub(id: "1"),
            "2": .stub(id: "2", name: "Ibuprofène")
        ]
        let sut = makeSUT()

        await sut.refresh()

        #expect(sut.medicines.count == 2)
        #expect(sut.loadError == nil)
    }

    @Test func refreshFailureSurfacesLoadError() async {
        mockMedicines.errorToThrow = MediStockError.networkUnavailable
        let sut = makeSUT()

        await sut.refresh()

        #expect(sut.medicines.isEmpty)
        #expect(sut.loadError == MediStockError.networkUnavailable.localizedDescription)
    }

    @Test func loadingFlagsAreClearedAfterSuccess() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1")]
        let sut = makeSUT()
        #expect(!sut.isLoading)

        await sut.loadIfNeeded()

        #expect(!sut.isLoading)
        #expect(sut.loadedForUserId == "test-user")
    }

    @Test func loadingFlagsAreClearedAfterFailure() async {
        mockMedicines.errorToThrow = MediStockError.networkUnavailable
        let sut = makeSUT()

        await sut.loadIfNeeded()

        #expect(!sut.isLoading)
        #expect(sut.loadedForUserId == "test-user")
    }

    @Test func loadMedicinesIfNeededReadsOnlyOnce() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1")]
        let sut = makeSUT()

        await sut.loadIfNeeded()
        await sut.loadIfNeeded()
        await sut.loadIfNeeded()

        #expect(mockMedicines.fetchCallCount == 1)
    }

    @Test func loadIfNeededFromBothTabsReadsOnlyOnce() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1")]
        let sut = makeSUT()
        let aisles = AisleListViewModel(store: sut)
        let list = MedicineListViewModel(store: sut)

        await aisles.loadIfNeeded()
        await list.loadIfNeeded()
        await sut.loadIfNeeded()

        #expect(mockMedicines.fetchCallCount == 1)
    }

    @Test func explicitRefreshAlwaysReads() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1")]
        let sut = makeSUT()

        await sut.loadIfNeeded()
        await sut.refresh()

        #expect(mockMedicines.fetchCallCount == 2)
    }

    @Test func explicitRefreshRecoversAfterAFailedInitialLoad() async {
        mockMedicines.errorToThrow = MediStockError.networkUnavailable
        let sut = makeSUT()
        await sut.loadIfNeeded()

        mockMedicines.errorToThrow = nil
        mockMedicines.storedMedicines = ["1": .stub(id: "1")]
        await sut.refresh()

        #expect(sut.medicines.count == 1)
        #expect(sut.loadError == nil)
    }

    @Test func loadErrorIsClearedByASuccessfulRefresh() async {
        mockMedicines.errorToThrow = MediStockError.networkUnavailable
        let sut = makeSUT()
        await sut.refresh()
        #expect(sut.loadError != nil)

        mockMedicines.errorToThrow = nil
        await sut.refresh()

        #expect(sut.loadError == nil)
    }

    // MARK: - Session invalidation

    @Test func sessionChangeTriggersAFreshRead() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1")]
        let sut = makeSUT()
        await sut.loadIfNeeded()

        mockAuth.currentUser = AppUser(id: "other-user", email: "other@medistock.app")
        await sut.loadIfNeeded()

        #expect(mockMedicines.fetchCallCount == 2)
        #expect(sut.loadedForUserId == "other-user")
    }

    @Test func sessionChangeEmptiesTheCollectionEvenWhenTheReloadFails() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1")]
        let sut = makeSUT()
        await sut.loadIfNeeded()
        #expect(sut.medicines.count == 1)

        mockAuth.currentUser = AppUser(id: "other-user", email: "other@medistock.app")
        mockMedicines.errorToThrow = MediStockError.networkUnavailable
        await sut.loadIfNeeded()

        #expect(sut.medicines.isEmpty)
        #expect(mockMedicines.fetchCallCount == 2)
    }

    @Test func signedOutSessionIsTreatedAsADifferentUser() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1")]
        let sut = makeSUT()
        await sut.loadIfNeeded()

        mockAuth.currentUser = nil
        await sut.loadIfNeeded()

        #expect(mockMedicines.fetchCallCount == 2)
        #expect(sut.loadedForUserId == nil)
    }
}
