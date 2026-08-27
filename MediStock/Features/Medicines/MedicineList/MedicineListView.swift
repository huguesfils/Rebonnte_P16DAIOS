import SwiftUI

struct MedicineListView: View {
    private let container: DIContainer
    @State private var viewModel: MedicineListViewModel

    init(container: DIContainer) {
        self.container = container
        _viewModel = State(initialValue: container.viewModelFactory.makeMedicineListViewModel())
    }

    var body: some View {
        let displayed = viewModel.filteredAndSortedMedicines

        return NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.isStockEmpty {
                    ProgressView("Chargement des médicaments…")
                } else if viewModel.isStockEmpty {
                    ContentUnavailableView(
                        "Aucun médicament",
                        systemImage: "pills",
                        description: Text("Ajoutez un premier médicament pour démarrer votre stock.")
                    )
                } else if displayed.isEmpty {
                    ContentUnavailableView.search(text: viewModel.filterText)
                } else {
                    list(displayed)
                }
            }
            .navigationTitle("Médicaments")
            .searchable(text: $viewModel.filterText, prompt: "Rechercher")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    SignOutButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    sortMenu
                }
                ToolbarItem(placement: .topBarTrailing) {
                    AddMedicineButton(container: container)
                }
            }
        }
        .errorAlert($viewModel.errorMessage)
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private var sortMenu: some View {
        Menu {
            Picker("Trier par", selection: $viewModel.sortOption) {
                ForEach(SortOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
        } label: {
            Label(
                "Trier par",
                systemImage: viewModel.sortOption == .none
                    ? "arrow.up.arrow.down"
                    : "arrow.up.arrow.down.circle.fill"
            )
        }
    }

    private func list(_ medicines: [Medicine]) -> some View {
        List {
            ForEach(medicines) { medicine in
                NavigationLink {
                    MedicineDetailView(medicineId: medicine.id, container: container)
                } label: {
                    MedicineRow(medicine: medicine)
                }
            }
            .onDelete { offsets in
                Task { await viewModel.delete(atOffsets: offsets) }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

#if DEBUG
#Preview {
    let container = DIContainer.preview
    MedicineListView(container: container)
        .environment(container.sessionManager)
}
#endif
