//
//  SettingView.swift
//  zola-app-swiftui
//
//  Created by 林晓中 on 2024/12/23.
//

import SwiftUI

struct SettingView: View {
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var settings: UserSettings
    @Binding var showingSettings: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("GitHub Settings")) {
                    TextField("Username", text: $settings.githubUsername)
                    TextField("Repository", text: $settings.githubRepo)
                    SecureField("GitHub Token", text: $settings.githubToken)
                }
                
                Section {
                    Text("The settings will be saved, so no need to enter them next time.")
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button(action: {
                        settings.logout()
                        showingSettings = false
                    }) {
                        Text("Logout")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

//#Preview {
//    SettingView()
//}
