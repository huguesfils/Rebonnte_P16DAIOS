import SwiftUI

@main
struct MediStockApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var container: DIContainer

    init() {
        _container = State(initialValue: DIContainer())
    }

    var body: some Scene {
        WindowGroup {
            if AppEnvironment.isRunningUnitTests {
                EmptyView()
            } else {
                ContentView(container: container)
                    .environment(container.sessionManager)
            }
        }
    }
}
