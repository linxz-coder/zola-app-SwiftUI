import SwiftUI
import SwiftDown

struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()
    @Environment(\.softwareKeyboard) var softwareKeyboard
    @Environment(\.colorScheme) var colorScheme  // 添加这一行来检测系统主题
    @StateObject var settings = UserSettings.shared
    @State var showingSettings = false
    
    let myDarkTheme = Theme(themePath: Bundle.main.path(forResource: "myDarkTheme", ofType: "json")!)

    
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
                        
//                        Text("Please configure your GitHub settings to continue")
//                            .foregroundColor(.secondary)
                        
                        Button("Configure GitHub Settings") {
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
                            Text("These settings will be saved locally and remembered even after you close the app.")
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
                    viewModel.isCheckingArticles = false  // 重置状态
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
                    if viewModel.customPathIsForArticles {
                        viewModel.fetchArticles(from: viewModel.customPath)
                    } else {
                        viewModel.uploadContent(path: viewModel.customPath)
                    }
                }
            } message: {
                Text("Start with /content/")
            }
            .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) { }
            }
            .sheet(isPresented: $viewModel.showArticlesList) {
                ArticlesListView(viewModel: viewModel)
            }
        }
    }
    
    var pathSelectionButtons: [ActionSheet.Button] {
        var buttons = predefinedPaths.map { path in
            ActionSheet.Button.default(Text(path)) {
                if viewModel.isCheckingArticles {
                    viewModel.fetchArticles(from: path)
                } else {
                    viewModel.uploadContent(path: path)
                }
            }
        }
        
        buttons += [
            .default(Text("Custom Path")) {
                viewModel.showCustomPathInput = true
                viewModel.customPathIsForArticles = viewModel.isCheckingArticles
            },
            .default(Text("Default (content)")) {
                if viewModel.isCheckingArticles {
                    viewModel.fetchArticles(from: "/content")
                } else {
                    viewModel.uploadContent(path: "/content")
                }
            },
            .cancel()
        ]
        
        return buttons
    }
}

#Preview {
    ContentView()
}
