import SwiftUI

struct MedicineDetailView: View {
    private let medicineId: String
    private let viewModel: MedicineStockViewModel

    @State private var draftName: String
    @State private var draftAisle: String
    @State private var draftStock: Int

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
            }
            .padding(.vertical)
        }
        .navigationBarTitle("Medicine Details", displayMode: .inline)
        .task {
            await viewModel.loadHistory(forMedicineId: medicineId)
        }
        .onChange(of: medicine?.stock) { _, stock in
            if let stock {
                draftStock = stock
            }
        }
    }
}

extension MedicineDetailView {
    private var medicineNameSection: some View {
        VStack(alignment: .leading) {
            Text("Name")
                .font(.headline)
            TextField("Name", text: $draftName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .submitLabel(.done)
                .onSubmit(saveDetails)
                .padding(.bottom, 10)
        }
        .padding(.horizontal)
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
                    .textFieldStyle(RoundedBorderTextFieldStyle())
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
            Text("Aisle")
                .font(.headline)
            TextField("Aisle", text: $draftAisle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .submitLabel(.done)
                .onSubmit(saveDetails)
                .padding(.bottom, 10)
        }
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func saveDetails() {
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
struct MedicineDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MedicineDetailView(
            medicine: Medicine(name: "Sample", stock: 10, aisle: "Aisle 1"),
            viewModel: .preview
        )
    }
}
#endif
