import SwiftUI
import SwiftDown

struct ContentView: View {
    
    @Environment(\.softwareKeyboard) var softwareKeyboard
    
    @StateObject var viewModel = ContentViewModel()
    @StateObject var settings = UserSettings.shared
    @State var showingSettings = false

    let predefinedPaths = [
        "/content/blog",
        "/content/shorts",
        "/content/books"
    ]
    
    var body: some View {
        NavigationStack {
            FormView(viewModel: viewModel, showingSettings: $showingSettings)
            .navigationTitle("Zola Now")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    
                    if softwareKeyboard?.isVisible == true {
                        Button("Done") {
                            softwareKeyboard?.dismiss()
                        }
                    } else {
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gear")
                        }
                    }
                }
            }
            
            .sheet(isPresented: $showingSettings) {
                SettingView(showingSettings: $showingSettings)
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
        }.environmentObject(settings)
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
