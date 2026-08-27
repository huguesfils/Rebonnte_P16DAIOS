import Foundation
import Testing
@testable import MediStock

struct NetworkAwareHistoryRepositoryTests {
    let wrapped = MockHistoryRepository(entries: [.stub(id: "history-1", medicineId: "1")])
    let monitor = MockNetworkMonitor()

    private func makeSUT() -> NetworkAwareHistoryRepository {
        NetworkAwareHistoryRepository(wrapping: wrapped, networkMonitor: monitor)
    }

    // MARK: - Exhaustivité du protocole

    enum Operation: CaseIterable {
        case fetchHistory
        case addEntry

        func run(on repository: HistoryRepository) async throws {
            switch self {
            case .fetchHistory:
                _ = try await repository.fetchHistory(medicineId: "1")
            case .addEntry:
                try await repository.addEntry(.stub(id: "history-2", medicineId: "1"))
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
        #expect(wrapped.addedEntries.isEmpty)
    }

    // MARK: - Connecté

    @Test func connectedOperationsPassThrough() async throws {
        let sut = makeSUT()

        let history = try await sut.fetchHistory(medicineId: "1")
        try await sut.addEntry(.stub(id: "history-2", medicineId: "1"))

        #expect(history.count == 1)
        #expect(wrapped.fetchCallCount == 1)
        #expect(wrapped.addedEntries.count == 1)
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
