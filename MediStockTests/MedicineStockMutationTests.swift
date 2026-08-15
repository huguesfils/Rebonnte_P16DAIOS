import Foundation
import Testing
@testable import MediStock

@MainActor
struct MedicineStockMutationTests {
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

    // MARK: - Stock

    @Test func increaseStockAppliesOptimisticUpdateWithoutReload() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", stock: 10)]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.increaseStock(medicineId: "1")

        #expect(sut.medicines.first?.stock == 11)
        #expect(mockMedicines.updatedStocks.first?.newStock == 11)
        #expect(mockMedicines.fetchCallCount == 1)
    }

    @Test func decreaseStockAppliesOptimisticUpdate() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", stock: 10)]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.decreaseStock(medicineId: "1")

        #expect(sut.medicines.first?.stock == 9)
    }

    @Test func stockUpdateFailureKeepsPreviousValue() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", stock: 10)]
        let sut = makeSUT()
        await sut.loadMedicines()
        mockMedicines.errorToThrow = MediStockError.networkUnavailable

        await sut.increaseStock(medicineId: "1")

        #expect(sut.medicines.first?.stock == 10)
        #expect(sut.errorMessage == MediStockError.networkUnavailable.localizedDescription)
    }

    @Test func stockUpdateWithoutUserIsRejected() async {
        mockAuth.currentUser = nil
        let sut = makeSUT()

        await sut.increaseStock(medicineId: "medicine-1")

        #expect(mockMedicines.updatedStocks.isEmpty)
        #expect(sut.errorMessage == MediStockError.notAuthenticated.localizedDescription)
    }

    @Test func repeatedIncrementsAccumulate() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", stock: 10)]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.increaseStock(medicineId: "1")
        await sut.increaseStock(medicineId: "1")
        await sut.increaseStock(medicineId: "1")

        #expect(sut.medicines.first?.stock == 13)
        #expect(mockMedicines.storedMedicines["1"]?.stock == 13)
        #expect(mockMedicines.updatedStocks.map(\.newStock) == [11, 12, 13])
    }

    @Test func repeatedDecrementsAccumulate() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", stock: 10)]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.decreaseStock(medicineId: "1")
        await sut.decreaseStock(medicineId: "1")

        #expect(sut.medicines.first?.stock == 8)
        #expect(mockMedicines.storedMedicines["1"]?.stock == 8)
    }

    @Test func historyDetailsReflectEachTransition() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", stock: 10)]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.increaseStock(medicineId: "1")
        await sut.increaseStock(medicineId: "1")

        #expect(mockHistory.addedEntries.map(\.details) == [
            "Stock changed from 10 to 11",
            "Stock changed from 11 to 12"
        ])
    }

    @Test func stockUpdateOnUnknownMedicineIsRejected() async {
        let sut = makeSUT()

        await sut.increaseStock(medicineId: "absent")

        #expect(mockMedicines.updatedStocks.isEmpty)
        #expect(sut.errorMessage == MediStockError.medicineNotFound.localizedDescription)
    }

    @Test func adjustmentIsRelativeSoAConcurrentChangeIsNotLost() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", stock: 10)]
        let sut = makeSUT()
        await sut.loadMedicines()

        mockMedicines.storedMedicines["1"]?.stock = 20

        await sut.increaseStock(medicineId: "1")

        #expect(mockMedicines.storedMedicines["1"]?.stock == 21)
        #expect(sut.medicines.first?.stock == 21)
        #expect(mockHistory.addedEntries.first?.details == "Stock changed from 20 to 21")
    }

    @Test func stockCannotGoNegative() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", stock: 0)]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.decreaseStock(medicineId: "1")

        #expect(mockMedicines.storedMedicines["1"]?.stock == 0)
        #expect(sut.medicines.first?.stock == 0)
        #expect(mockHistory.addedEntries.isEmpty)
        #expect(sut.errorMessage == MediStockError.negativeStock.localizedDescription)
    }

    // MARK: - setStock

    @Test func setStockAppliesAbsoluteValue() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", stock: 10)]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.setStock(medicineId: "1", to: 42)

        #expect(sut.medicines.first?.stock == 42)
        #expect(mockHistory.addedEntries.first?.details == "Stock changed from 10 to 42")
    }

    @Test func setStockToSameValueWritesNothing() async {
        mockMedicines.storedMedicines = ["1": .stub(id: "1", stock: 10)]
        let sut = makeSUT()
        await sut.loadMedicines()

        await sut.setStock(medicineId: "1", to: 10)

        #expect(mockMedicines.updatedStocks.isEmpty)
        #expect(mockHistory.addedEntries.isEmpty)
    }
}
