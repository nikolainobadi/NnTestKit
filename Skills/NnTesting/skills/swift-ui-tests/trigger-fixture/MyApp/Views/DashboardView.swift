import SwiftUI

struct DashboardView: View {
    @State private var projects = ["Alpha", "Beta", "Gamma"]

    var body: some View {
        NavigationStack {
            List(projects, id: \.self) { Text($0) }
                .navigationTitle("Welcome")
        }
    }
}
