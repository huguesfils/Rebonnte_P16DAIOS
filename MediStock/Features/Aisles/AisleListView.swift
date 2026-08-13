import SwiftUI

struct AisleListView: View {
    private let viewModel: MedicineStockViewModel

    init(viewModel: MedicineStockViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.aisles, id: \.self) { aisle in
                    NavigationLink(destination: MedicineListView(aisle: aisle, viewModel: viewModel)) {
                        Text(aisle)
                    }
                }
            }
            .navigationBarTitle("Aisles")
            .navigationBarItems(
                leading: SignOutButton(),
                trailing: Button(action: {
                    Task { await viewModel.addRandomMedicine() }
                }) {
                    Image(systemName: "plus")
                }
            )
        }
        .task {
            await viewModel.loadMedicines()
        }
    }
}

#if DEBUG
struct AisleListView_Previews: PreviewProvider {
    static var previews: some View {
        AisleListView(viewModel: .preview)
            .environment(DIContainer.preview.sessionManager)
    }
}
#endif
