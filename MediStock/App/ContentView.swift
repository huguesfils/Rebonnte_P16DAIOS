import SwiftUI

struct ContentView: View {
    @Environment(SessionManager.self) private var session

    private let container: DIContainer

    init(container: DIContainer) {
        self.container = container
    }

    var body: some View {
        @Bindable var session = session

        return Group {
            switch session.currentScreen {
            case .loading:
                ProgressView()
            case .login:
                LoginView(container: container)
            case .main:
                MainTabView(container: container)
            }
        }
        .task {
            session.start()
        }
        .errorAlert($session.errorMessage)
    }
}

#if DEBUG
#Preview {
    let container = DIContainer.preview
    ContentView(container: container)
        .environment(container.sessionManager)
}
#endif
