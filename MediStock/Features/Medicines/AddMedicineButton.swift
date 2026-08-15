import SwiftUI

struct AddMedicineButton: View {
    let viewModel: MedicineStockViewModel

    @State private var isPresentingForm = false

    var body: some View {
        Button("Ajouter un médicament", systemImage: "plus") {
            isPresentingForm = true
        }
        .sheet(isPresented: $isPresentingForm) {
            AddMedicineView(viewModel: viewModel)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        Text("Contenu")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AddMedicineButton(viewModel: .preview)
                }
            }
    }
}
#endif
