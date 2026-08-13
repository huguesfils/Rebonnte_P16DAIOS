import SwiftUI

struct MedicineListView: View {
    private let aisle: String
    private let viewModel: MedicineStockViewModel

    init(aisle: String, viewModel: MedicineStockViewModel) {
        self.aisle = aisle
        self.viewModel = viewModel
    }

    private var medicines: [Medicine] {
        viewModel.medicines(inAisle: aisle)
    }

    var body: some View {
        List {
            ForEach(medicines) { medicine in
                NavigationLink(destination: MedicineDetailView(medicine: medicine, viewModel: viewModel)) {
                    VStack(alignment: .leading) {
                        Text(medicine.name)
                            .font(.headline)
                        Text("Stock: \(medicine.stock)")
                            .font(.subheadline)
                    }
                }
            }
            .onDelete { offsets in
                Task { await viewModel.delete(atOffsets: offsets, in: medicines) }
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
