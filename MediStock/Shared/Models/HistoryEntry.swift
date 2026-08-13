import Foundation

struct HistoryEntry: Identifiable, Equatable, Sendable {
    let id: String
    let medicineId: String
    let user: String
    let action: String
    let details: String
    let timestamp: Date

    init(
        id: String = UUID().uuidString,
        medicineId: String,
        user: String,
        action: String,
        details: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.medicineId = medicineId
        self.user = user
        self.action = action
        self.details = details
        self.timestamp = timestamp
    }
}
