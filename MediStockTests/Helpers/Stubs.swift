import Foundation
@testable import MediStock

extension Medicine {
    static func stub(
        id: String = "medicine-1",
        name: String = "Doliprane",
        stock: Int = 10,
        aisle: String = "Rayon 1"
    ) -> Medicine {
        Medicine(id: id, name: name, stock: stock, aisle: aisle)
    }
}

extension HistoryEntry {
    static func stub(
        id: String = "history-1",
        medicineId: String = "medicine-1",
        user: String = "test-user",
        userEmail: String? = "test@medistock.app",
        action: String = "Ajout de Doliprane",
        details: String = "Créé avec un stock de 12 dans Rayon 1",
        timestamp: Date = Date()
    ) -> HistoryEntry {
        HistoryEntry(
            id: id,
            medicineId: medicineId,
            user: user,
            userEmail: userEmail,
            action: action,
            details: details,
            timestamp: timestamp
        )
    }
}
