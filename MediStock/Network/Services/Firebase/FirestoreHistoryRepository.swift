import Foundation
import FirebaseFirestore

struct FirestoreHistoryRepository: HistoryRepository {
    static let pageSize = 25

    private var collection: CollectionReference {
        Firestore.firestore().collection("history")
    }

    // MARK: - Read

    func fetchHistory(medicineId: String) async throws -> [HistoryEntry] {
        do {
            let snapshot = try await collection
                .whereField("medicineId", isEqualTo: medicineId)
                .order(by: "timestamp", descending: true)
                .limit(to: Self.pageSize)
                .getDocuments()
            return snapshot.documents.compactMap(Self.makeEntry(from:))
        } catch {
            throw FirestoreErrorMapper.map(error)
        }
    }

    // MARK: - Write

    func addEntry(_ entry: HistoryEntry) async throws {
        do {
            var data: [String: Any] = [
                "medicineId": entry.medicineId,
                "user": entry.user,
                "action": entry.action,
                "details": entry.details,
                "timestamp": Timestamp(date: entry.timestamp)
            ]
            data["userEmail"] = entry.userEmail

            try await collection.document(entry.id).setData(data)
        } catch {
            throw FirestoreErrorMapper.map(error)
        }
    }

    // MARK: - Mapping

    static func date(from value: Any?) -> Date? {
        if let timestamp = value as? Timestamp { return timestamp.dateValue() }
        return value as? Date
    }

    private static func makeEntry(from document: QueryDocumentSnapshot) -> HistoryEntry? {
        makeEntry(id: document.documentID, data: document.data())
    }

    static func makeEntry(id: String, data: [String: Any]) -> HistoryEntry? {
        guard let medicineId = data["medicineId"] as? String,
              let user = data["user"] as? String,
              let action = data["action"] as? String,
              let details = data["details"] as? String,
              let timestamp = date(from: data["timestamp"]) else {
            return nil
        }
        return HistoryEntry(
            id: id,
            medicineId: medicineId,
            user: user,
            userEmail: data["userEmail"] as? String,
            action: action,
            details: details,
            timestamp: timestamp
        )
    }
}
