import Foundation
import Testing
@testable import MediStock

struct FirestoreMappingTests {
    // MARK: - Medicine

    @Test func medicineIsMappedFromACompleteDocument() throws {
        let medicine = try #require(FirestoreMedicineRepository.makeMedicine(
            id: "doc-1",
            data: ["name": "Doliprane", "stock": 12, "aisle": "Rayon 3"]
        ))

        #expect(medicine.id == "doc-1")
        #expect(medicine.name == "Doliprane")
        #expect(medicine.stock == 12)
        #expect(medicine.aisle == "Rayon 3")
    }

    @Test func unknownFieldsAreIgnored() throws {
        let medicine = try #require(FirestoreMedicineRepository.makeMedicine(
            id: "doc-1",
            data: ["name": "Doliprane", "stock": 1, "aisle": "A", "legacyField": "à ignorer"]
        ))

        #expect(medicine.name == "Doliprane")
    }

    @Test("Document médicament incomplet ou mal typé", arguments: [
        ["stock": 12, "aisle": "A"] as [String: Any],
        ["name": "Doliprane", "aisle": "A"],
        ["name": "Doliprane", "stock": 12],
        ["name": "Doliprane", "stock": "douze", "aisle": "A"],
        ["name": 42, "stock": 12, "aisle": "A"],
        [:]
    ])
    func malformedMedicineDocumentsAreDropped(data: [String: Any]) {
        #expect(FirestoreMedicineRepository.makeMedicine(id: "doc-1", data: data) == nil)
    }

    // MARK: - History

    @Test func historyEntryIsMappedFromACompleteDocument() throws {
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let entry = try #require(FirestoreHistoryRepository.makeEntry(
            id: "hist-1",
            data: [
                "medicineId": "med-1",
                "user": "uid-1",
                "userEmail": "operateur@medistock.app",
                "action": "Stock de Doliprane augmenté de 1",
                "details": "Stock passé de 10 à 11",
                "timestamp": timestamp
            ]
        ))

        #expect(entry.id == "hist-1")
        #expect(entry.medicineId == "med-1")
        #expect(entry.user == "uid-1")
        #expect(entry.userEmail == "operateur@medistock.app")
        #expect(entry.timestamp == timestamp)
    }

    @Test func historyEntryWithoutEmailFallsBackToTheIdentifier() throws {
        let entry = try #require(FirestoreHistoryRepository.makeEntry(
            id: "hist-1",
            data: [
                "medicineId": "med-1",
                "user": "uid-1",
                "action": "a",
                "details": "d",
                "timestamp": Date()
            ]
        ))

        #expect(entry.userEmail == nil)
        #expect(entry.displayedUser == "uid-1")
    }

    @Test("Document d'historique incomplet", arguments: [
        ["user": "u", "action": "a", "details": "d"] as [String: Any],
        ["medicineId": "m", "action": "a", "details": "d"],
        ["medicineId": "m", "user": "u", "details": "d"],
        ["medicineId": "m", "user": "u", "action": "a"],
        [:]
    ])
    func malformedHistoryDocumentsAreDropped(data: [String: Any]) {
        var payload = data
        if payload["timestamp"] == nil, !payload.isEmpty {
            payload["timestamp"] = Date()
        }
        #expect(FirestoreHistoryRepository.makeEntry(id: "hist-1", data: payload) == nil)
    }

    @Test func historyEntryWithoutTimestampIsDropped() {
        let entry = FirestoreHistoryRepository.makeEntry(
            id: "hist-1",
            data: ["medicineId": "m", "user": "u", "action": "a", "details": "d"]
        )

        #expect(entry == nil)
    }

    @Test func timestampAcceptsBothDateAndFirestoreValue() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        #expect(FirestoreHistoryRepository.date(from: date) == date)
        #expect(FirestoreHistoryRepository.date(from: nil) == nil)
        #expect(FirestoreHistoryRepository.date(from: "pas une date") == nil)
    }

    // MARK: - Transaction payload

    @Test func stockChangeIsDecodedFromTheTransactionPayload() throws {
        let change = try FirestoreMedicineRepository.decodeStockChange(from: [
            FirestoreMedicineRepository.previousKey: 10,
            FirestoreMedicineRepository.newKey: 11
        ])

        #expect(change == StockChange(previous: 10, new: 11))
    }

    @Test func missingMedicinePayloadThrows() {
        #expect(throws: MediStockError.medicineNotFound) {
            try FirestoreMedicineRepository.decodeStockChange(
                from: [FirestoreMedicineRepository.notFoundKey: true]
            )
        }
    }

    @Test func negativeStockPayloadThrows() {
        #expect(throws: MediStockError.negativeStock) {
            try FirestoreMedicineRepository.decodeStockChange(
                from: [FirestoreMedicineRepository.negativeKey: true]
            )
        }
    }

    @Test("Payload de transaction inexploitable", arguments: [
        nil,
        "pas un dictionnaire" as Any,
        [:] as [String: Any],
        [FirestoreMedicineRepository.previousKey: 10] as [String: Any],
        [FirestoreMedicineRepository.previousKey: "dix", FirestoreMedicineRepository.newKey: 11] as [String: Any]
    ])
    func malformedPayloadThrowsInvalidData(payload: Any?) {
        #expect(throws: MediStockError.invalidData) {
            try FirestoreMedicineRepository.decodeStockChange(from: payload)
        }
    }
}
