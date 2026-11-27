import SwiftUI

struct SettingsView: View {
    @AppStorage("darkMode") private var darkMode = false

    var body: some View {
        Form { Toggle("Dark Mode", isOn: $darkMode) }
            .navigationTitle("Settings")
    }
}
