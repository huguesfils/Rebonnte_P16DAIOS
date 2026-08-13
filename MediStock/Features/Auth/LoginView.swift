import SwiftUI

struct LoginView: View {
    @Environment(SessionManager.self) private var session
    @State private var viewModel: LoginViewModel

    init(container: DIContainer) {
        _viewModel = State(initialValue: container.viewModelFactory.makeLoginViewModel())
    }

    var body: some View {
        VStack(spacing: 24) {
            header

            Picker("Mode", selection: $viewModel.mode) {
                ForEach(AuthMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            fields

            submitButton

            Spacer()
        }
        .padding()
        .errorAlert($viewModel.errorMessage)
        .onChange(of: viewModel.authenticatedUser) { _, user in
            if let user {
                session.onAuthenticated(user)
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "cross.case.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("MediStock")
                .font(.largeTitle)
                .bold()
        }
        .padding(.top, 40)
        .accessibilityElement(children: .combine)
    }

    private var fields: some View {
        VStack(spacing: 12) {
            TextField("Email", text: $viewModel.email)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.next)

            SecureField("Mot de passe", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
                .textContentType(viewModel.mode == .signUp ? .newPassword : .password)
                .submitLabel(.go)
                .onSubmit { submit() }

            if viewModel.mode == .signUp {
                Text("Au moins \(LoginViewModel.minimumPasswordLength) caractères.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var submitButton: some View {
        Button(action: submit) {
            Group {
                if viewModel.isAuthenticating {
                    ProgressView()
                } else {
                    Text(viewModel.mode.title)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!viewModel.canSubmit)
    }

    // MARK: - Actions

    private func submit() {
        Task { await viewModel.submit() }
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        let container = DIContainer.preview
        return LoginView(container: container)
            .environment(container.sessionManager)
    }
}
#endif
