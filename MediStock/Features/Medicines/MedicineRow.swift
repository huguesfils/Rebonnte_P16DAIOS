import SwiftUI

struct MedicineRow: View {
    let medicine: Medicine

    private var isOutOfStock: Bool {
        medicine.stock == 0
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(medicine.name)
                .font(.headline)

            Spacer()

            if isOutOfStock {
                Label("Rupture", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.red)
            } else {
                Text(medicine.stock, format: .number)
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            isOutOfStock
                ? "\(medicine.name), en rupture de stock"
                : "\(medicine.name), stock \(medicine.stock)"
        )
    }
}

#if DEBUG
#Preview {
    List {
        MedicineRow(medicine: Medicine(name: "Doliprane", stock: 12, aisle: "Rayon 1"))
        MedicineRow(medicine: Medicine(name: "Ibuprofène", stock: 0, aisle: "Rayon 2"))
    }
}
#endif
