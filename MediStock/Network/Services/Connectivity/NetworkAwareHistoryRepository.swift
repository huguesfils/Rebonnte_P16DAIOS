import Foundation

struct NetworkAwareHistoryRepository: HistoryRepository {
    private let wrapped: HistoryRepository
    private let networkMonitor: NetworkMonitor

    init(wrapping wrapped: HistoryRepository, networkMonitor: NetworkMonitor) {
        self.wrapped = wrapped
        self.networkMonitor = networkMonitor
    }

    // MARK: - Read

    func fetchHistory(medicineId: String) async throws -> [HistoryEntry] {
        try requireConnection()
        return try await wrapped.fetchHistory(medicineId: medicineId)
    }

    // MARK: - Write

    func addEntry(_ entry: HistoryEntry) async throws {
        try requireConnection()
        try await wrapped.addEntry(entry)
    }

    // MARK: - Connectivity

    private func requireConnection() throws {
        guard networkMonitor.isConnected else {
            throw MediStockError.networkUnavailable
        }
    }
}
