import SwiftUI

struct ContentView: View {
    @Environment(SessionManager.self) private var session

    private let container: DIContainer

    init(container: DIContainer) {
        self.container = container
    }

    var body: some View {
        Group {
            switch session.currentScreen {
            case .loading:
                ProgressView()
            case .login:
                LoginView()
            case .main:
                MainTabView(container: container)
            }
        }
        .task {
            session.start()
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let container = DIContainer.preview
        return ContentView(container: container)
            .environment(container.sessionManager)
    }
}
#endif
