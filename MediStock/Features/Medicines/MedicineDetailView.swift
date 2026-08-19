import SwiftUI

struct MedicineDetailView: View {
    @Environment(\.dismiss) private var dismiss

    private let medicineId: String
    private let viewModel: MedicineStockViewModel

    @State private var draftName: String
    @State private var draftAisle: String
    @State private var draftStock: Int
    @State private var isConfirmingDeletion = false

    init(medicine: Medicine, viewModel: MedicineStockViewModel) {
        medicineId = medicine.id
        self.viewModel = viewModel
        _draftName = State(initialValue: medicine.name)
        _draftAisle = State(initialValue: medicine.aisle)
        _draftStock = State(initialValue: medicine.stock)
    }

    private var medicine: Medicine? {
        viewModel.medicine(withId: medicineId)
    }

    var body: some View {
        Form {
            identitySection

            stockSection

            MedicineHistorySection(
                entries: viewModel.history,
                isLoading: viewModel.isLoadingHistory
            )

            deleteSection
        }
        .navigationTitle(medicine?.name ?? draftName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadHistory(forMedicineId: medicineId)
        }
        .onChange(of: medicine?.stock) { _, stock in
            if let stock {
                draftStock = stock
            }
        }
        .confirmationDialog(
            "Supprimer ce médicament ?",
            isPresented: $isConfirmingDeletion,
            titleVisibility: .visible
        ) {
            Button("Supprimer", role: .destructive, action: delete)
        } message: {
            Text("Le médicament sera retiré du stock. L'historique de ses mouvements est conservé.")
        }
    }
}

// MARK: - Sections

extension MedicineDetailView {
    private var identitySection: some View {
        Section {
            LabeledContent("Nom") {
                TextField("Nom", text: $draftName)
                    .multilineTextAlignment(.trailing)
                    .submitLabel(.done)
                    .onSubmit(saveDetails)
            }

            LabeledContent("Rayon") {
                TextField("Rayon", text: $draftAisle)
                    .multilineTextAlignment(.trailing)
                    .submitLabel(.done)
                    .onSubmit(saveDetails)
            }
        } header: {
            Text("Médicament")
        } footer: {
            if !areDetailsValid {
                Text("Le nom et le rayon ne peuvent pas être vides.")
                    .foregroundStyle(.red)
            }
        }
    }

    private var stockSection: some View {
        Section("Stock") {
            HStack {
                Button("Diminuer le stock", systemImage: "minus") {
                    Task { await viewModel.decreaseStock(medicineId: medicineId) }
                }
                .disabled(draftStock == 0)

                Spacer()

                TextField("Stock", value: $draftStock, format: .number)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .font(.title3.monospacedDigit())
                    .submitLabel(.done)
                    .onSubmit(saveStock)
                    .frame(maxWidth: 100)

                Spacer()

                Button("Augmenter le stock", systemImage: "plus") {
                    Task { await viewModel.increaseStock(medicineId: medicineId) }
                }
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
        }
    }

    private var deleteSection: some View {
        Section {
            Button("Supprimer ce médicament", systemImage: "trash", role: .destructive) {
                isConfirmingDeletion = true
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var areDetailsValid: Bool {
        MedicineInput.isValid(name: draftName, aisle: draftAisle, stock: draftStock)
    }

    // MARK: - Actions

    private func delete() {
        Task {
            if await viewModel.delete(medicineId: medicineId) {
                dismiss()
            }
        }
    }

    private func saveDetails() {
        guard areDetailsValid else { return }

        Task {
            await viewModel.updateDetails(medicineId: medicineId, name: draftName, aisle: draftAisle)
        }
    }

    private func saveStock() {
        Task {
            await viewModel.setStock(medicineId: medicineId, to: draftStock)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        MedicineDetailView(
            medicine: Medicine(id: "preview-1", name: "Doliprane", stock: 12, aisle: "Rayon 1"),
            viewModel: .preview
        )
    }
}
#endif
