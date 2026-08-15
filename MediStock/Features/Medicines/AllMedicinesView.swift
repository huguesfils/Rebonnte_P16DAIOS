import SwiftUI

struct AllMedicinesView: View {
    private let viewModel: MedicineStockViewModel

    @State private var filterText = ""
    @State private var sortOption: SortOption = .none

    init(viewModel: MedicineStockViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sortPicker

                Group {
                    if viewModel.isLoadingMedicines && viewModel.medicines.isEmpty {
                        ProgressView("Chargement des médicaments…")
                    } else if viewModel.medicines.isEmpty {
                        ContentUnavailableView(
                            "Aucun médicament",
                            systemImage: "pills",
                            description: Text("Ajoutez un premier médicament pour démarrer votre stock.")
                        )
                    } else if filteredAndSortedMedicines.isEmpty {
                        ContentUnavailableView.search(text: filterText)
                    } else {
                        list
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .navigationTitle("Médicaments")
            .searchable(text: $filterText, prompt: "Rechercher")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    SignOutButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    AddMedicineButton(viewModel: viewModel)
                }
            }
        }
    }

    private var sortPicker: some View {
        Picker("Trier par", selection: $sortOption) {
            ForEach(SortOption.allCases) { option in
                Text(option.title).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var list: some View {
        List {
            ForEach(filteredAndSortedMedicines) { medicine in
                NavigationLink {
                    MedicineDetailView(medicine: medicine, viewModel: viewModel)
                } label: {
                    MedicineRow(medicine: medicine)
                }
            }
            .onDelete { offsets in
                Task { await viewModel.delete(atOffsets: offsets, in: filteredAndSortedMedicines) }
            }
        }
        .refreshable {
            await viewModel.loadMedicines()
        }
    }

    private var filteredAndSortedMedicines: [Medicine] {
        var medicines = viewModel.medicines

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
}

#if DEBUG
#Preview {
    AllMedicinesView(viewModel: .preview)
        .environment(DIContainer.preview.sessionManager)
}
#endif
