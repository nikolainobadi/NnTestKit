import SwiftUI

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var isLoggedIn = false

    var body: some View {
        if !hasOnboarded { OnboardingView(onFinish: { hasOnboarded = true }) }
        else if !isLoggedIn { LoginView(onLogin: { isLoggedIn = true }) }
        else { DashboardView() }
    }
}
