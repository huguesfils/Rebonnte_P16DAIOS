import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case none
    case name
    case stock

    var id: String { rawValue }
}
