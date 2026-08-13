import SwiftUI

struct SignOutButton: View {
    @Environment(SessionManager.self) private var session
    @State private var isConfirming = false

    var body: some View {
        Button("Déconnexion", systemImage: "rectangle.portrait.and.arrow.right") {
            isConfirming = true
        }
        .labelStyle(.iconOnly)
        .confirmationDialog(
            "Se déconnecter ?",
            isPresented: $isConfirming,
            titleVisibility: .visible
        ) {
            Button("Se déconnecter", role: .destructive) {
                session.signOut()
            }
        } message: {
            Text("Vous devrez saisir vos identifiants pour vous reconnecter.")
        }
    }
}

#if DEBUG
struct SignOutButton_Previews: PreviewProvider {
    static var previews: some View {
        SignOutButton()
            .environment(DIContainer.preview.sessionManager)
    }
}
#endif
