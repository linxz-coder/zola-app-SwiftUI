import SwiftUI
import SwiftDown

struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()
    @Environment(\.softwareKeyboard) var softwareKeyboard
    @Environment(\.colorScheme) var colorScheme  // 添加这一行来检测系统主题
    @StateObject var settings = UserSettings.shared
    @State var showingSettings = false
    
    let predefinedPaths = [
        "/content/blog",
        "/content/shorts",
        "/content/books"
    ]
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
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
                                .theme(colorScheme == .dark ? Theme.BuiltIn.defaultDark.theme() : Theme.BuiltIn.defaultLight.theme())
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
                                Button("Source Text"){
                                    viewModel.showSourceText = true
                                }
                                .buttonStyle(.borderedProminent)
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
                        
                        Text("Please configure your GitHub settings to continue")
                            .foregroundColor(.secondary)
                        
                        Button("Configure Settings") {
                            showingSettings = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                // keyboard button现在在ZStack内部
                if softwareKeyboard?.isVisible == true {
                    HStack {
                        Spacer()
                        Button("Done") {
                            softwareKeyboard?.dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                    .frame(height: 45)
                    .background(Color(UIColor.systemBackground))
                    .animation(.none, value: softwareKeyboard?.isVisible)  // 移除动画效果
                    .transition(.identity)  // 使用 identity transition 移除过渡动画
                }
            }
            .navigationTitle("Zola Now")
            
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
            
            .sheet(isPresented: $showingSettings) {
                NavigationView {
                    Form {
                        Section(header: Text("GitHub Settings")) {
                            TextField("Username", text: $settings.githubUsername)
                            TextField("Repository", text: $settings.githubRepo)
                            SecureField("GitHub Token", text: $settings.githubToken)
                        }
                        
                        Section {
                            Text("These settings will be saved and remembered even after you close the app.")
                                .foregroundColor(.secondary)
                        }
                    }
                    .navigationTitle("Settings")
                    .navigationBarItems(trailing: Button("Done") {
                        showingSettings = false
                    })
                }
            }
            
            .sheet(isPresented: $viewModel.showSourceText) {
                SourceTextView(text: viewModel.structuredText)
            }
            .alert("Confirm Upload", isPresented: $viewModel.showUploadAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Confirm") {
                    viewModel.showPathSelection = true
                }
            } message: {
                Text("Do you want to upload this file?")
            }
            .actionSheet(isPresented: $viewModel.showPathSelection) {
                ActionSheet(
                    title: Text("Select Upload Path"),
                    message: Text("Choose or enter a path (default: content)"),
                    buttons: pathSelectionButtons
                )
            }
            .alert("Enter Custom Path", isPresented: $viewModel.showCustomPathInput) {
                TextField("Path", text: $viewModel.customPath)
                Button("Cancel", role: .cancel) { }
                Button("Confirm") {
                    viewModel.uploadContent(path: viewModel.customPath)
                }
            } message: {
                Text("Start with /content/")
            }
            .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }
    
    var pathSelectionButtons: [ActionSheet.Button] {
        var buttons = predefinedPaths.map { path in
            ActionSheet.Button.default(Text(path)) {
                viewModel.uploadContent(path: path)
            }
        }
        
        buttons += [
            .default(Text("Custom Path")) {
                viewModel.showCustomPathInput = true
            },
            .default(Text("Default (content)")) {
                viewModel.uploadContent(path: "/content")
            },
            .cancel()
        ]
        
        return buttons
    }
}

#Preview {
    ContentView()
}
