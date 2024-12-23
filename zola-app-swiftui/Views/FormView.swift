//
//  FormView.swift
//  zola-app-swiftui
//
//  Created by 林晓中 on 2024/12/23.
//

import SwiftUI
import SwiftDown

struct FormView: View {
    
    @ObservedObject var viewModel: ContentViewModel
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var settings: UserSettings
    @Binding var showingSettings: Bool
    
    let myDarkTheme = Theme(themePath: Bundle.main.path(forResource: "myDarkTheme", ofType: "json")!)
    
    var body: some View {
        if settings.isConfigured {
            Form {
                Section(header: Text("Front Matter")) {
                    TextField("Title", text:$viewModel.title)
                        .frame(height:50)
                        .font(.title2)
                    DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                    TextField("Author", text: $viewModel.author)
                }
                
                Section(header: Text("Content")) {
                    SwiftDownEditor(text: $viewModel.content)
                        .theme(colorScheme == .dark ? myDarkTheme : Theme.BuiltIn.defaultLight.theme())
                        .frame(height: 200)
                }
                
                Section(header: Text("Tags")) {
                    ForEach(0..<3) { index in
                        if index == 0 || !viewModel.tags[index - 1].isEmpty {
                            TextField("Tag \(index + 1)", text: $viewModel.tags[index])
                        }
                    }
                }
                
                Section {
                    HStack(spacing: 30) {
                        
                        Button("Upload to Zola"){
                            viewModel.showUploadAlert = true
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(width:100)
                        
                        Button("Check Articles") {
                            viewModel.showPathSelection = true
                            viewModel.isCheckingArticles = true
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(width:100)
                        
                        Button("Source Text"){
                            viewModel.showSourceText = true
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(width:100)
//                        NavigationLink{
//                            SourceTextView(text: viewModel.structuredText)
//                        } label: {
//                            Text("Source Text")
//                                .frame(width: 70)
//                                .padding(8)
//                                .background(Color.accentColor)
//                                .foregroundColor(.white)
//                                .cornerRadius(8)
//                                .multilineTextAlignment(.center)
//                        }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
        } else {
            VStack(spacing: 20) {
                Text("Welcome to Zola Now")
                    .font(.title)
                    .padding()
                
                Button("Configure GitHub Settings") {
                    showingSettings = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

//#Preview {
//    FormView(viewModel: ContentViewModel(),showingSettings: false)
//}
