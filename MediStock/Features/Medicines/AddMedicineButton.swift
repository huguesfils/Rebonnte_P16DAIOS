import SwiftUI

struct AddMedicineButton: View {
    let container: DIContainer

    @State private var isPresentingForm = false

    var body: some View {
        Button("Ajouter un médicament", systemImage: "plus") {
            isPresentingForm = true
        }
        .sheet(isPresented: $isPresentingForm) {
            AddMedicineView(container: container)
        }
    }
}

#if DEBUG
#Preview {
    let container = DIContainer.preview
    NavigationStack {
        Text("Contenu")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AddMedicineButton(container: container)
                }
            }
    }
}
#endif
