import Foundation
@testable import MediStock

final class MockNetworkMonitor: NetworkMonitor, @unchecked Sendable {
    var isConnected: Bool

    init(isConnected: Bool = true) {
        self.isConnected = isConnected
    }
}
