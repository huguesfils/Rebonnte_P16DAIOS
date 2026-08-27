import Foundation
import Network
import Synchronization

final class NWPathNetworkMonitor: NetworkMonitor, Sendable {
    private let pathMonitor = NWPathMonitor()
    private let connectedFlag = Mutex(true)

    var isConnected: Bool { connectedFlag.withLock { $0 } }

    init() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            self?.update(with: path)
        }
        pathMonitor.start(queue: DispatchQueue(label: "app.medistock.network-monitor"))
    }

    deinit {
        pathMonitor.cancel()
    }

    // MARK: - Path updates

    private func update(with path: NWPath) {
        connectedFlag.withLock { $0 = path.status == .satisfied }
    }
}
