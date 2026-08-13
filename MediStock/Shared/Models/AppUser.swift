import Foundation

struct AppUser: Identifiable, Equatable, Sendable {
    let id: String
    let email: String?
}
