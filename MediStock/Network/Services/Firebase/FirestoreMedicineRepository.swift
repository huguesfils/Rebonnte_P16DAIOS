import Foundation
import FirebaseFirestore

struct FirestoreMedicineRepository: MedicineRepository {
    private var collection: CollectionReference {
        Firestore.firestore().collection("medicines")
    }

    // MARK: - Read

    func fetchMedicines() async throws -> [Medicine] {
        do {
            let snapshot = try await collection.getDocuments()
            return snapshot.documents.compactMap(Self.makeMedicine(from:))
        } catch {
            throw FirestoreErrorMapper.map(error)
        }
    }

    // MARK: - Write

    func save(_ medicine: Medicine) async throws {
        do {
            try await collection.document(medicine.id).setData([
                "name": medicine.name,
                "stock": medicine.stock,
                "aisle": medicine.aisle
            ])
        } catch {
            throw FirestoreErrorMapper.map(error)
        }
    }

    func adjustStock(medicineId: String, by amount: Int) async throws -> StockChange {
        try await commitStockChange(medicineId: medicineId) { $0 + amount }
    }

    func setStock(medicineId: String, to newStock: Int) async throws -> StockChange {
        try await commitStockChange(medicineId: medicineId) { _ in newStock }
    }

    func delete(medicineId: String) async throws {
        do {
            try await collection.document(medicineId).delete()
        } catch {
            throw FirestoreErrorMapper.map(error)
        }
    }

    // MARK: - Atomic stock

    private func commitStockChange(
        medicineId: String,
        resolve: @escaping @Sendable (Int) -> Int
    ) async throws -> StockChange {
        let reference = collection.document(medicineId)
        let firestore = Firestore.firestore()

        let outcome: Any?
        do {
            outcome = try await firestore.runTransaction { transaction, _ -> Any? in
                guard let snapshot = try? transaction.getDocument(reference),
                      let previous = snapshot.data()?["stock"] as? Int else {
                    return [Self.notFoundKey: true]
                }

                let resolved = resolve(previous)
                guard resolved >= 0 else { return [Self.negativeKey: true] }

                if resolved != previous {
                    transaction.updateData(["stock": resolved], forDocument: reference)
                }
                return [Self.previousKey: previous, Self.newKey: resolved]
            }
        } catch {
            throw FirestoreErrorMapper.map(error)
        }

        guard let payload = outcome as? [String: Any] else {
            throw MediStockError.invalidData
        }
        if payload[Self.notFoundKey] != nil { throw MediStockError.medicineNotFound }
        if payload[Self.negativeKey] != nil { throw MediStockError.negativeStock }

        guard let previous = payload[Self.previousKey] as? Int,
              let new = payload[Self.newKey] as? Int else {
            throw MediStockError.invalidData
        }

        return StockChange(previous: previous, new: new)
    }

    private static let notFoundKey = "notFound"
    private static let negativeKey = "negative"
    private static let previousKey = "previous"
    private static let newKey = "new"

    // MARK: - Mapping

    private static func makeMedicine(from document: QueryDocumentSnapshot) -> Medicine? {
        let data = document.data()
        guard let name = data["name"] as? String,
              let stock = data["stock"] as? Int,
              let aisle = data["aisle"] as? String else {
            return nil
        }
        return Medicine(id: document.documentID, name: name, stock: stock, aisle: aisle)
    }
}
