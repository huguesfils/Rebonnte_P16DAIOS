import SwiftUI

struct MedicineHistorySection: View {
    let entries: [HistoryEntry]

    var body: some View {
        VStack(alignment: .leading) {
            Text("History")
                .font(.headline)
                .padding(.top, 20)

            if entries.isEmpty {
                Text("Aucun mouvement enregistré pour ce médicament.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entries) { entry in
                    MedicineHistoryRow(entry: entry)
                }
            }
        }
        .padding(.horizontal)
    }
}

private struct MedicineHistoryRow: View {
    let entry: HistoryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(entry.action)
                .font(.headline)
            Text("User: \(entry.user)")
                .font(.subheadline)
            Text("Date: \(entry.timestamp.formatted())")
                .font(.subheadline)
            Text("Details: \(entry.details)")
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.bottom, 5)
    }
}

#if DEBUG
struct MedicineHistorySection_Previews: PreviewProvider {
    static var previews: some View {
        MedicineHistorySection(entries: [
            HistoryEntry(
                medicineId: "1",
                user: "operateur@medistock.app",
                action: "Increased stock of Doliprane by 1",
                details: "Stock changed from 10 to 11"
            )
        ])
    }
}
#endif
