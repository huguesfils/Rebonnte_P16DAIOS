import Foundation

@Observable
@MainActor
final class AddMedicineViewModel {
    var name = ""
    var aisle = ""
    var stock = 0
    var errorMessage: String?

    private(set) var isSaving = false

    var canSave: Bool { !isSaving && MedicineInput.isValid(name: name, aisle: aisle, stock: stock) }

    private let store: MedicineStore

    init(store: MedicineStore) {
        self.store = store
    }

    func save() async -> Bool {
        isSaving = true
        defer { isSaving = false }

        do {
            try await store.addMedicine(name: name, stock: stock, aisle: aisle)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
