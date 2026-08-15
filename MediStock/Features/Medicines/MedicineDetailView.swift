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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(medicine?.name ?? draftName)
                    .font(.largeTitle)
                    .padding(.top, 20)

                medicineNameSection

                medicineStockSection

                medicineAisleSection

                MedicineHistorySection(entries: viewModel.history)

                deleteSection
            }
            .padding(.vertical)
        }
        .navigationTitle("Détail du médicament")
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

extension MedicineDetailView {
    private var medicineNameSection: some View {
        VStack(alignment: .leading) {
            Text("Nom")
                .font(.headline)
            TextField("Nom", text: $draftName)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .onSubmit(saveDetails)

            invalidDetailsHint

            Spacer().frame(height: 10)
        }
        .padding(.horizontal)
    }

    private var areDetailsValid: Bool {
        MedicineInput.isValid(name: draftName, aisle: draftAisle, stock: draftStock)
    }

    @ViewBuilder
    private var invalidDetailsHint: some View {
        if !areDetailsValid {
            Text("Le nom et le rayon ne peuvent pas être vides.")
                .font(.footnote)
                .foregroundStyle(.red)
                .accessibilityLabel("Saisie invalide : le nom et le rayon ne peuvent pas être vides")
        }
    }

    private var medicineStockSection: some View {
        VStack(alignment: .leading) {
            Text("Stock")
                .font(.headline)
            HStack {
                Button("Diminuer le stock", systemImage: "minus.circle") {
                    Task { await viewModel.decreaseStock(medicineId: medicineId) }
                }
                .labelStyle(.iconOnly)
                .font(.title)
                .foregroundStyle(.red)

                TextField("Stock", value: $draftStock, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(width: 100)
                    .submitLabel(.done)
                    .onSubmit(saveStock)

                Button("Augmenter le stock", systemImage: "plus.circle") {
                    Task { await viewModel.increaseStock(medicineId: medicineId) }
                }
                .labelStyle(.iconOnly)
                .font(.title)
                .foregroundStyle(.green)
            }
            .padding(.bottom, 10)
        }
        .padding(.horizontal)
    }

    private var medicineAisleSection: some View {
        VStack(alignment: .leading) {
            Text("Rayon")
                .font(.headline)
            TextField("Rayon", text: $draftAisle)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .onSubmit(saveDetails)
                .padding(.bottom, 10)
        }
        .padding(.horizontal)
    }

    private var deleteSection: some View {
        Button("Supprimer ce médicament", systemImage: "trash", role: .destructive) {
            isConfirmingDeletion = true
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
        .padding(.horizontal)
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
            medicine: Medicine(id: "preview-1", name: "Doliprane", stock: 12, aisle: "Aisle 1"),
            viewModel: .preview
        )
    }
}
#endif
