import SwiftUI

struct MainTabView: View {
    private let container: DIContainer

    init(container: DIContainer) {
        self.container = container
    }

    var body: some View {
        TabView {
            Tab("Rayons", systemImage: "list.dash") {
                AisleListView(container: container)
            }

            Tab("Médicaments", systemImage: "square.grid.2x2") {
                MedicineListView(container: container)
            }
        }
    }
}

#if DEBUG
#Preview {
    let container = DIContainer.preview
    MainTabView(container: container)
        .environment(container.sessionManager)
}
#endif
