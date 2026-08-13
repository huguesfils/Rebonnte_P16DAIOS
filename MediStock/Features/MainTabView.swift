import SwiftUI

struct MainTabView: View {
    @State private var viewModel: MedicineStockViewModel

    init(container: DIContainer) {
        _viewModel = State(initialValue: container.viewModelFactory.makeMedicineStockViewModel())
    }

    var body: some View {
        TabView {
            AisleListView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "list.dash")
                    Text("Aisles")
                }

            AllMedicinesView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "square.grid.2x2")
                    Text("All Medicines")
                }
        }
        .errorAlert($viewModel.errorMessage)
    }
}

#if DEBUG
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(container: .preview)
            .environment(DIContainer.preview.sessionManager)
    }
}
#endif
