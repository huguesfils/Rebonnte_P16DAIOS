import SwiftUI

struct AisleMedicinesView: View {
    private let container: DIContainer
    @State private var viewModel: AisleMedicinesViewModel

    init(aisle: String, container: DIContainer) {
        self.container = container
        _viewModel = State(
            initialValue: container.viewModelFactory.makeAisleMedicinesViewModel(aisle: aisle)
        )
    }

    var body: some View {
        Group {
            if viewModel.medicines.isEmpty {
                ContentUnavailableView(
                    "Rayon vide",
                    systemImage: "tray",
                    description: Text("Ce rayon ne contient plus aucun médicament.")
                )
            } else {
                list
            }
        }
        .navigationTitle(viewModel.aisle)
        .navigationBarTitleDisplayMode(.inline)
        .errorAlert($viewModel.errorMessage)
    }

    private var list: some View {
        List {
            ForEach(viewModel.medicines) { medicine in
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
    NavigationStack {
        AisleMedicinesView(aisle: "Rayon 1", container: container)
    }
}
#endif
