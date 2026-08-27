import Foundation
import Testing
@testable import MediStock

struct NetworkAwareMedicineRepositoryTests {
    let wrapped = MockMedicineRepository(medicines: [.stub(id: "1")])
    let monitor = MockNetworkMonitor()

    private func makeSUT() -> NetworkAwareMedicineRepository {
        NetworkAwareMedicineRepository(wrapping: wrapped, networkMonitor: monitor)
    }

    // MARK: - Exhaustivité du protocole

    enum Operation: CaseIterable {
        case fetchMedicines
        case save
        case adjustStock
        case setStock
        case delete

        func run(on repository: MedicineRepository) async throws {
            switch self {
            case .fetchMedicines:
                _ = try await repository.fetchMedicines()
            case .save:
                try await repository.save(.stub(id: "1"))
            case .adjustStock:
                _ = try await repository.adjustStock(medicineId: "1", by: 1)
            case .setStock:
                _ = try await repository.setStock(medicineId: "1", to: 5)
            case .delete:
                try await repository.delete(medicineId: "1")
            }
        }
    }

    // MARK: - Hors-ligne

    @Test(arguments: Operation.allCases)
    func offlineOperationsFailFast(operation: Operation) async {
        monitor.isConnected = false
        let sut = makeSUT()

        await #expect(throws: MediStockError.networkUnavailable) {
            try await operation.run(on: sut)
        }
    }

    @Test(arguments: Operation.allCases)
    func offlineOperationsSkipTheRepository(operation: Operation) async {
        monitor.isConnected = false
        let sut = makeSUT()

        try? await operation.run(on: sut)

        #expect(wrapped.fetchCallCount == 0)
        #expect(wrapped.savedMedicines.isEmpty)
        #expect(wrapped.updatedStocks.isEmpty)
        #expect(wrapped.deletedIds.isEmpty)
    }

    // MARK: - Connecté

    @Test func connectedFetchReturnsTheWrappedContent() async throws {
        let sut = makeSUT()

        let medicines = try await sut.fetchMedicines()

        #expect(medicines.count == 1)
        #expect(medicines.first?.id == "1")
        #expect(wrapped.fetchCallCount == 1)
    }

    @Test func connectedSaveForwardsTheMedicine() async throws {
        let sut = makeSUT()

        try await sut.save(.stub(id: "2", name: "Ibuprofène"))

        #expect(wrapped.savedMedicines.count == 1)
        #expect(wrapped.savedMedicines.first?.id == "2")
    }

    @Test func connectedStockChangesReturnTheirResult() async throws {
        let sut = makeSUT()

        let increased = try await sut.adjustStock(medicineId: "1", by: 1)
        let assigned = try await sut.setStock(medicineId: "1", to: 5)

        #expect(increased == StockChange(previous: 10, new: 11))
        #expect(assigned == StockChange(previous: 11, new: 5))
    }

    @Test func connectedDeleteForwardsTheId() async throws {
        let sut = makeSUT()

        try await sut.delete(medicineId: "1")

        #expect(wrapped.deletedIds == ["1"])
    }

    @Test(arguments: Operation.allCases)
    func connectedErrorsAreRethrownUnchanged(operation: Operation) async {
        wrapped.errorToThrow = MediStockError.permissionDenied
        let sut = makeSUT()

        await #expect(throws: MediStockError.permissionDenied) {
            try await operation.run(on: sut)
        }
    }
}
