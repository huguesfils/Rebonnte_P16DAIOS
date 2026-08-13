import SwiftUI

struct MedicineListView: View {
    private let aisle: String
    private let viewModel: MedicineStockViewModel

    init(aisle: String, viewModel: MedicineStockViewModel) {
        self.aisle = aisle
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            ForEach(viewModel.medicines(inAisle: aisle)) { medicine in
                NavigationLink(destination: MedicineDetailView(medicine: medicine, viewModel: viewModel)) {
                    VStack(alignment: .leading) {
                        Text(medicine.name)
                            .font(.headline)
                        Text("Stock: \(medicine.stock)")
                            .font(.subheadline)
                    }
                }
            }
        }
        .navigationBarTitle(aisle)
        .task {
            await viewModel.loadMedicines()
        }
    }
}

#if DEBUG
struct MedicineListView_Previews: PreviewProvider {
    static var previews: some View {
        MedicineListView(aisle: "Aisle 1", viewModel: .preview)
    }
}
#endif
