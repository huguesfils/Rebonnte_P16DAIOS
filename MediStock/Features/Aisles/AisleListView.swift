import SwiftUI

struct AisleListView: View {
    private let viewModel: MedicineStockViewModel

    init(viewModel: MedicineStockViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoadingMedicines && viewModel.aisles.isEmpty {
                    ProgressView("Chargement des rayons…")
                } else if viewModel.aisles.isEmpty {
                    ContentUnavailableView(
                        "Aucun rayon",
                        systemImage: "shippingbox",
                        description: Text("Ajoutez un médicament pour créer votre premier rayon.")
                    )
                } else {
                    aisleList
                }
            }
            .navigationTitle("Rayons")
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

    private var aisleList: some View {
        List(viewModel.aisles, id: \.self) { aisle in
            NavigationLink(value: aisle) {
                Text(aisle)
            }
            .accessibilityHint("Affiche les médicaments de ce rayon")
        }
        .navigationDestination(for: String.self) { aisle in
            AisleMedicinesView(aisle: aisle, viewModel: viewModel)
        }
        .refreshable {
            await viewModel.loadMedicines()
        }
    }
}

#if DEBUG
#Preview {
    AisleListView(viewModel: .preview)
        .environment(DIContainer.preview.sessionManager)
}
#endif
