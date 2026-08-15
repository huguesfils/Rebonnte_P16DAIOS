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
        Group {
            if medicines.isEmpty {
                ContentUnavailableView(
                    "Rayon vide",
                    systemImage: "tray",
                    description: Text("Ce rayon ne contient plus aucun médicament.")
                )
            } else {
                list
            }
        }
        .navigationTitle(aisle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var list: some View {
        List {
            ForEach(medicines) { medicine in
                NavigationLink {
                    MedicineDetailView(medicine: medicine, viewModel: viewModel)
                } label: {
                    MedicineRow(medicine: medicine)
                }
            }
            .onDelete { offsets in
                Task { await viewModel.delete(atOffsets: offsets, in: medicines) }
            }
        }
        .refreshable {
            await viewModel.loadMedicines()
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        MedicineListView(aisle: "Aisle 1", viewModel: .preview)
    }
}
#endif
