import SwiftUI

struct LoginView: View {
    let onLogin: () -> Void
    @State private var email = ""
    @State private var acceptedTerms = false

    var body: some View {
        Form {
            TextField("Email", text: $email)
            Toggle("I accept the terms", isOn: $acceptedTerms)
            Button("Continue", action: onLogin).disabled(email.isEmpty || !acceptedTerms)
            Button("Try Demo", action: onLogin)
        }
    }
}
