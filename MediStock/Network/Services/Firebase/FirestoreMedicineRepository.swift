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

    func updateStock(medicineId: String, newStock: Int) async throws {
        do {
            try await collection.document(medicineId).updateData(["stock": newStock])
        } catch {
            throw FirestoreErrorMapper.map(error)
        }
    }

    func delete(medicineId: String) async throws {
        do {
            try await collection.document(medicineId).delete()
        } catch {
            throw FirestoreErrorMapper.map(error)
        }
    }

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
