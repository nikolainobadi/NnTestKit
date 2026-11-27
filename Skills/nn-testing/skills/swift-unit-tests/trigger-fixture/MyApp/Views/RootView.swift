import SwiftUI

struct RootView: View {
    @State private var finishedOnboarding = false
    @State private var loggedIn = false

    var body: some View {
        if !finishedOnboarding {
            OnboardingView(onFinish: { finishedOnboarding = true })
        } else if !loggedIn {
            LoginView(onLogin: { loggedIn = true })
        } else {
            Text("Home")
        }
    }
}
