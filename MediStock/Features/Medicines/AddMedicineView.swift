import SwiftUI

struct AddMedicineView: View {
    @Environment(\.dismiss) private var dismiss

    private let viewModel: MedicineStockViewModel

    @State private var name = ""
    @State private var aisle = ""
    @State private var stock = 0
    @State private var isSaving = false

    init(viewModel: MedicineStockViewModel) {
        self.viewModel = viewModel
    }

    private var canSave: Bool {
        !isSaving && MedicineInput.isValid(name: name, aisle: aisle, stock: stock)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Médicament") {
                    TextField("Nom", text: $name)
                        .textInputAutocapitalization(.words)
                    TextField("Rayon", text: $aisle)
                        .textInputAutocapitalization(.words)
                }

                Section("Stock initial") {
                    Stepper("\(stock)", value: $stock, in: 0...9999)
                }
            }
            .navigationTitle("Nouveau médicament")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: save) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Ajouter").bold()
                        }
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        isSaving = true

        Task {
            let didSave = await viewModel.addMedicine(name: name, stock: stock, aisle: aisle)
            isSaving = false

            if didSave {
                dismiss()
            }
        }
    }
}

#if DEBUG
#Preview {
    AddMedicineView(viewModel: .preview)
}
#endif
