import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0
    private let titles = ["Track", "Plan", "Share", "Ready"]

    var body: some View {
        TabView(selection: $page) {
            ForEach(titles.indices, id: \.self) { index in
                VStack {
                    Text(titles[index])
                    if index == titles.count - 1 { Button("Get Started", action: onFinish) }
                }
                .tag(index)
            }
        }
        .tabViewStyle(.page)
    }
}
