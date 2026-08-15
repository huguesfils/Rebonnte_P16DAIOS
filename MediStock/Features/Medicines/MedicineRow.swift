import SwiftUI

struct MedicineRow: View {
    let medicine: Medicine

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(medicine.name)
                .font(.headline)
            Text("Stock : \(medicine.stock)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(medicine.name), stock \(medicine.stock)")
    }
}

#if DEBUG
#Preview {
    List {
        MedicineRow(medicine: Medicine(name: "Doliprane", stock: 12, aisle: "Aisle 1"))
        MedicineRow(medicine: Medicine(name: "Ibuprofène", stock: 0, aisle: "Aisle 2"))
    }
}
#endif
