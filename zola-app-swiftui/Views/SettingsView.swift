import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @FocusState private var settingsFocused: Bool  // 独立的 FocusState
    @ObservedObject var settings: UserSettings
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("GitHub Settings")) {
                    TextField("Username", text: $settings.githubUsername)
                        .focused($settingsFocused)
                    TextField("Repository", text: $settings.githubRepo)
                        .focused($settingsFocused)
                    SecureField("GitHub Token", text: $settings.githubToken)
                        .focused($settingsFocused)
                }
                
                Section {
                    Text("These settings will be saved locally and remembered even after you close the app.")
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button(action: {
                        settings.logout()
                        dismiss()
                    }) {
                        Text("Logout")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Finish") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        settingsFocused = false
                    }
                }
            }
        }
    }
}
