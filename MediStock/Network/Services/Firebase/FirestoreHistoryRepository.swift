import Foundation
import FirebaseFirestore

struct FirestoreHistoryRepository: HistoryRepository {
    private var collection: CollectionReference {
        Firestore.firestore().collection("history")
    }

    // MARK: - Read

    func fetchHistory(medicineId: String) async throws -> [HistoryEntry] {
        do {
            let snapshot = try await collection
                .whereField("medicineId", isEqualTo: medicineId)
                .getDocuments()
            return snapshot.documents
                .compactMap(Self.makeEntry(from:))
                .sorted { $0.timestamp > $1.timestamp }
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

    private static func makeEntry(from document: QueryDocumentSnapshot) -> HistoryEntry? {
        let data = document.data()
        guard let medicineId = data["medicineId"] as? String,
              let user = data["user"] as? String,
              let action = data["action"] as? String,
              let details = data["details"] as? String,
              let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else {
            return nil
        }
        return HistoryEntry(
            id: document.documentID,
            medicineId: medicineId,
            user: user,
            userEmail: data["userEmail"] as? String,
            action: action,
            details: details,
            timestamp: timestamp
        )
    }
}
