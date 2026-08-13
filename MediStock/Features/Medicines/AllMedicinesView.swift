import SwiftUI

struct AllMedicinesView: View {
    private let viewModel: MedicineStockViewModel

    @State private var filterText = ""
    @State private var sortOption: SortOption = .none
    @State private var isAddingMedicine = false

    init(viewModel: MedicineStockViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Filter by name", text: $filterText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading, 10)

                    Spacer()

                    Picker("Sort by", selection: $sortOption) {
                        Text("None").tag(SortOption.none)
                        Text("Name").tag(SortOption.name)
                        Text("Stock").tag(SortOption.stock)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.trailing, 10)
                }
                .padding(.top, 10)

                List {
                    ForEach(filteredAndSortedMedicines) { medicine in
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
                        Task { await viewModel.delete(atOffsets: offsets, in: filteredAndSortedMedicines) }
                    }
                }
                .navigationBarTitle("All Medicines")
                .navigationBarItems(
                    leading: SignOutButton(),
                    trailing: Button("Ajouter un médicament", systemImage: "plus") {
                        isAddingMedicine = true
                    }
                    .labelStyle(.iconOnly)
                )
                .sheet(isPresented: $isAddingMedicine) {
                    AddMedicineView(viewModel: viewModel)
                }
            }
        }
        .task {
            await viewModel.loadMedicines()
        }
    }

    private var filteredAndSortedMedicines: [Medicine] {
        var medicines = viewModel.medicines

        if !filterText.isEmpty {
            medicines = medicines.filter { $0.name.lowercased().contains(filterText.lowercased()) }
        }

        switch sortOption {
        case .name:
            medicines.sort { $0.name.lowercased() < $1.name.lowercased() }
        case .stock:
            medicines.sort { $0.stock < $1.stock }
        case .none:
            break
        }

        return medicines
    }
}

#if DEBUG
struct AllMedicinesView_Previews: PreviewProvider {
    static var previews: some View {
        AllMedicinesView(viewModel: .preview)
            .environment(DIContainer.preview.sessionManager)
    }
}
#endif
