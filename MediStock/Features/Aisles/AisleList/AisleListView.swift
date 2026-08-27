import SwiftUI

struct AisleListView: View {
    private let container: DIContainer
    @State private var viewModel: AisleListViewModel

    init(container: DIContainer) {
        self.container = container
        _viewModel = State(initialValue: container.viewModelFactory.makeAisleListViewModel())
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.aisles.isEmpty {
                    ProgressView("Chargement des rayons…")
                } else if viewModel.aisles.isEmpty {
                    ContentUnavailableView {
                        Label("Aucun rayon", systemImage: "shippingbox")
                    } description: {
                        Text("Ajoutez un médicament pour créer votre premier rayon.")
                    } actions: {
                        Button("Réessayer") {
                            Task { await viewModel.refresh() }
                        }
                    }
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
                    AddMedicineButton(container: container)
                }
            }
        }
        .errorAlert($viewModel.errorMessage)
        .task {
            await viewModel.loadIfNeeded()
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
