import Foundation

protocol HistoryRepository: Sendable {
    func fetchHistory(medicineId: String) async throws -> [HistoryEntry]
    func addEntry(_ entry: HistoryEntry) async throws
}
