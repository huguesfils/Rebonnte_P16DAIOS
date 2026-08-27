import Foundation

protocol NetworkMonitor: Sendable {
    var isConnected: Bool { get }
}
