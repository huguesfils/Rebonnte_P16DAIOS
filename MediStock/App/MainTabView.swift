import SwiftUI

struct MainTabView: View {
    @State private var viewModel: MedicineStockViewModel

    init(container: DIContainer) {
        _viewModel = State(initialValue: container.viewModelFactory.makeMedicineStockViewModel())
    }

    var body: some View {
        TabView {
            Tab("Rayons", systemImage: "list.dash") {
                AisleListView(viewModel: viewModel)
            }

            Tab("Médicaments", systemImage: "square.grid.2x2") {
                MedicineListView(viewModel: viewModel)
            }
        }
        .errorAlert($viewModel.errorMessage)
        .task {
            await viewModel.loadMedicinesIfNeeded()
        }
    }
}

#if DEBUG
#Preview {
    MainTabView(container: .preview)
        .environment(DIContainer.preview.sessionManager)
}
#endif
