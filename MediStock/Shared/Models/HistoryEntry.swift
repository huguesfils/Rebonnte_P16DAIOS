import Foundation

struct HistoryEntry: Identifiable, Equatable, Sendable {
    let id: String
    let medicineId: String
    let user: String
    let userEmail: String?
    let action: String
    let details: String
    let timestamp: Date

    var displayedUser: String {
        guard let userEmail, !userEmail.isEmpty else { return user }
        return userEmail
    }

    init(
        id: String = UUID().uuidString,
        medicineId: String,
        user: String,
        userEmail: String? = nil,
        action: String,
        details: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.medicineId = medicineId
        self.user = user
        self.userEmail = userEmail
        self.action = action
        self.details = details
        self.timestamp = timestamp
    }
}
