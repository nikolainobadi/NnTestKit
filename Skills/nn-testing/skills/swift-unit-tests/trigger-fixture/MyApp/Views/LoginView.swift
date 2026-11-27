import SwiftUI

struct LoginView: View {
    let onLogin: () -> Void
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        Form {
            TextField("Email", text: $email)
            SecureField("Password", text: $password)
            Button("Log In", action: onLogin).disabled(email.isEmpty || password.isEmpty)
        }
    }
}
