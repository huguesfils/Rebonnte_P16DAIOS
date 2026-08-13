import SwiftUI

struct ContentView: View {
    @Environment(SessionViewModel.self) private var session

    private let container: DIContainer

    init(container: DIContainer) {
        self.container = container
    }

    var body: some View {
        Group {
            if session.isAuthenticated {
                MainTabView(container: container)
            } else {
                LoginView()
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
            .environment(container.sessionViewModel)
    }
}
#endif
