import SwiftUI

struct MedicineHistorySection: View {
    let entries: [HistoryEntry]
    let isLoading: Bool

    var body: some View {
        Section("Historique") {
            if isLoading && entries.isEmpty {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Chargement de l'historique…")
                        .foregroundStyle(.secondary)
                }
            } else if entries.isEmpty {
                Text("Aucun mouvement enregistré pour ce médicament.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entries) { entry in
                    MedicineHistoryRow(entry: entry)
                }
            }
        }
    }
}

private struct MedicineHistoryRow: View {
    let entry: HistoryEntry

    private var formattedDate: String {
        entry.timestamp.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.action)
                .font(.subheadline)
                .bold()

            Text(entry.details)
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack {
                Text(entry.displayedUser)
                Spacer()
                Text(formattedDate)
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.action). \(entry.details). Par \(entry.displayedUser), le \(formattedDate)")
    }
}

#if DEBUG
#Preview {
    Form {
        MedicineHistorySection(
            entries: [
                HistoryEntry(
                    medicineId: "1",
                    user: "uid",
                    userEmail: "operateur@medistock.app",
                    action: "Stock de Doliprane augmenté de 1",
                    details: "Stock passé de 10 à 11"
                )
            ],
            isLoading: false
        )

        MedicineHistorySection(entries: [], isLoading: false)
    }
}
#endif
