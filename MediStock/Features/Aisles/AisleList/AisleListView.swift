import SwiftUI

struct AisleListView: View {
    private let container: DIContainer
    @State private var viewModel: AisleListViewModel

    init(container: DIContainer) {
        self.container = container
        _viewModel = State(initialValue: container.viewModelFactory.makeAisleListViewModel())
    }

    var body: some View {
        let aisles = viewModel.aisles

        return NavigationStack {
            Group {
                if viewModel.isLoading && aisles.isEmpty {
                    ProgressView("Chargement des rayons…")
                } else if aisles.isEmpty {
                    ContentUnavailableView(
                        "Aucun rayon",
                        systemImage: "shippingbox",
                        description: Text("Ajoutez un médicament pour créer votre premier rayon.")
                    )
                } else {
                    aisleList(aisles)
                }
            }
            .navigationTitle("Rayons")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    SignOutButton()
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

    private func aisleList(_ aisles: [String]) -> some View {
        List(aisles, id: \.self) { aisle in
            NavigationLink(value: aisle) {
                Text(aisle)
            }
            .accessibilityHint("Affiche les médicaments de ce rayon")
        }
        .navigationDestination(for: String.self) { aisle in
            AisleMedicinesView(aisle: aisle, container: container)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

#if DEBUG
#Preview {
    let container = DIContainer.preview
    AisleListView(container: container)
        .environment(container.sessionManager)
}
#endif
