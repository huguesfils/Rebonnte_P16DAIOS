import SwiftUI

struct ProfileView: View {
    @Environment(SessionManager.self) private var session
    @State private var viewModel: ProfileViewModel
    @State private var isConfirmingDeletion = false
    @State private var password = ""

    init(container: DIContainer) {
        _viewModel = State(initialValue: container.viewModelFactory.makeProfileViewModel())
    }

    var body: some View {
        @Bindable var session = session

        NavigationStack {
            Form {
                Section("Compte") {
                    LabeledContent("Adresse e-mail", value: viewModel.email)
                }

                Section("Application") {
                    LabeledContent("Version", value: viewModel.appVersion)
                }

                Section {
                    deleteAccountButton
                } footer: {
                    Text("La suppression est définitive. Les mouvements de stock que vous avez enregistrés "
                         + "restent dans l'historique, car il fait office de journal d'audit.")
                }
            }
            .navigationTitle("Profil")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    SignOutButton()
                }
            }
            .errorAlert($session.errorMessage)
        }
        .alert("Supprimer votre compte ?", isPresented: $isConfirmingDeletion) {
            SecureField("Mot de passe", text: $password)
            Button("Annuler", role: .cancel) {
                password = ""
            }
            Button("Supprimer", role: .destructive) {
                let confirmedPassword = password
                password = ""
                Task { await session.deleteAccount(password: confirmedPassword) }
            }
        } message: {
            Text("Cette action est définitive. Saisissez votre mot de passe pour confirmer : "
                 + "vous perdrez l'accès à l'application et devrez créer un nouveau compte.")
        }
    }

    private var deleteAccountButton: some View {
        Button(role: .destructive) {
            isConfirmingDeletion = true
        } label: {
            HStack {
                Text("Supprimer mon compte")
                if session.isDeletingAccount {
                    Spacer()
                    ProgressView()
                }
            }
        }
        .disabled(session.isDeletingAccount)
    }
}

#if DEBUG
#Preview {
    let container = DIContainer.preview
    ProfileView(container: container)
        .environment(container.sessionManager)
}
#endif
