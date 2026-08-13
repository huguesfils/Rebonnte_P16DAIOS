import SwiftUI

struct LoginView: View {
    @Environment(SessionManager.self) private var session

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button("Login") {
                Task { await session.signIn(email: email, password: password) }
            }
            Button("Sign Up") {
                Task { await session.signUp(email: email, password: password) }
            }
        }
        .padding()
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environment(DIContainer.preview.sessionManager)
    }
}
#endif
