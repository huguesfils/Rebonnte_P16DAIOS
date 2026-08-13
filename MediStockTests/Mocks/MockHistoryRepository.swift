import Foundation
@testable import MediStock

final class MockHistoryRepository: HistoryRepository, @unchecked Sendable {
    var storedEntries: [HistoryEntry] = []
    var errorToThrow: Error?

    private(set) var fetchCallCount = 0
    private(set) var addedEntries: [HistoryEntry] = []

    init(entries: [HistoryEntry] = []) {
        storedEntries = entries
    }

    func fetchHistory(medicineId: String) async throws -> [HistoryEntry] {
        fetchCallCount += 1
        if let errorToThrow { throw errorToThrow }
        return storedEntries
            .filter { $0.medicineId == medicineId }
            .sorted { $0.timestamp > $1.timestamp }
    }

    func addEntry(_ entry: HistoryEntry) async throws {
        if let errorToThrow { throw errorToThrow }
        storedEntries.append(entry)
        addedEntries.append(entry)
    }
}
