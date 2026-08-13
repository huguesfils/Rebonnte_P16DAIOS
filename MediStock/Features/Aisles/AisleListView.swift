import SwiftUI

struct AisleListView: View {
    private let viewModel: MedicineStockViewModel

    @State private var isAddingMedicine = false

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
                trailing: Button("Ajouter un médicament", systemImage: "plus") {
                    isAddingMedicine = true
                }
                .labelStyle(.iconOnly)
            )
            .sheet(isPresented: $isAddingMedicine) {
                AddMedicineView(viewModel: viewModel)
            }
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
