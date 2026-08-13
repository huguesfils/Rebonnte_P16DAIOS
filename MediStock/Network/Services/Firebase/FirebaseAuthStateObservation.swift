import Foundation
import FirebaseAuth

final class FirebaseAuthStateObservation: AuthStateObservation, @unchecked Sendable {
    private let handle: AuthStateDidChangeListenerHandle

    init(handle: AuthStateDidChangeListenerHandle) {
        self.handle = handle
    }

    func cancel() {
        Auth.auth().removeStateDidChangeListener(handle)
    }
}
