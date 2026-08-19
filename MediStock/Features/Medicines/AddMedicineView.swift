import SwiftUI

struct AddMedicineView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: AddMedicineViewModel

    init(container: DIContainer) {
        _viewModel = State(initialValue: container.viewModelFactory.makeAddMedicineViewModel())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Médicament") {
                    TextField("Nom", text: $viewModel.name)
                        .textInputAutocapitalization(.words)
                    TextField("Rayon", text: $viewModel.aisle)
                        .textInputAutocapitalization(.words)
                }

                Section("Stock initial") {
                    Stepper("\(viewModel.stock)", value: $viewModel.stock, in: 0...9999)
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
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("Ajouter").bold()
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
        .errorAlert($viewModel.errorMessage)
    }

    private func save() {
        Task {
            if await viewModel.save() {
                dismiss()
            }
        }
    }
}

#if DEBUG
#Preview {
    AddMedicineView(container: .preview)
}
#endif
