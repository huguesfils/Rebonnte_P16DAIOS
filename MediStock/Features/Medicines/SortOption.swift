import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case none
    case name
    case stock

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: "Aucun"
        case .name: "Nom"
        case .stock: "Stock"
        }
    }
}
