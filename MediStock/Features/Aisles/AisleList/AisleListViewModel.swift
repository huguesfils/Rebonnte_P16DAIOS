import Foundation

@Observable
@MainActor
final class AisleListViewModel {
    var errorMessage: String?

    var isLoading: Bool { store.isLoading }
    var aisles: [String] { Set(store.medicines.map(\.aisle)).sorted() }

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
}
