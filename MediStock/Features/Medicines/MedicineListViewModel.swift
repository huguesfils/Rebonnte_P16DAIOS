import Foundation

@Observable
@MainActor
final class MedicineListViewModel {
    var filterText = ""
    var sortOption: SortOption = .none
    var errorMessage: String?

    var isLoading: Bool { store.isLoading }
    var isStockEmpty: Bool { store.medicines.isEmpty }

    var filteredAndSortedMedicines: [Medicine] {
        var medicines = store.medicines

        if !filterText.isEmpty {
            medicines = medicines.filter { $0.name.localizedCaseInsensitiveContains(filterText) }
        }

        switch sortOption {
        case .name:
            medicines.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .stock:
            medicines.sort { $0.stock < $1.stock }
        case .none:
            break
        }

        return medicines
    }

    private let store: MedicineStore

    init(store: MedicineStore) {
        self.store = store
    }

    func loadIfNeeded() async {
        await store.loadIfNeeded()
        errorMessage = store.loadError
    }

    func refresh() async {
        await store.refresh()
        errorMessage = store.loadError
    }

    func delete(atOffsets offsets: IndexSet) async {
        let displayed = filteredAndSortedMedicines
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
