import Foundation

@Observable
@MainActor
final class AisleMedicinesViewModel {
    let aisle: String
    var errorMessage: String?

    var medicines: [Medicine] { store.medicines.filter { $0.aisle == aisle } }

    private let store: MedicineStore

    init(aisle: String, store: MedicineStore) {
        self.aisle = aisle
        self.store = store
    }

    func refresh() async {
        await store.refresh()
        errorMessage = store.loadError
    }

    func delete(atOffsets offsets: IndexSet) async {
        let displayed = medicines
        let ids = offsets.compactMap { displayed.indices.contains($0) ? displayed[$0].id : nil }

        do {
            for id in ids {
                try await store.delete(medicineId: id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
