import SwiftUI
import SwiftDown

struct ContentView: View {
    // MARK: - Properties
    @Environment(\.softwareKeyboard) var softwareKeyboard
    @StateObject var viewModel = ContentViewModel()
    @StateObject var settings = UserSettings.shared
    @State var showingSettings = false
    
    let predefinedPaths = [
        "/content/blog",
        "/content/shorts",
        "/content/books"
    ]
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            // Main Content
            FormView(viewModel: viewModel, showingSettings: $showingSettings)
                .navigationTitle("Zola Now")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        toolbarButton
                    }
                }
            
                // MARK: - Sheets
                .sheet(isPresented: $showingSettings) {
                    SettingView(showingSettings: $showingSettings)
                }
                .sheet(isPresented: $viewModel.showSourceText) {
                    SourceTextView(text: viewModel.structuredText)
                }
                .sheet(isPresented: $viewModel.showArticlesList) {
                    ArticlesListView(viewModel: viewModel)
                }
            
                // MARK: - Alerts and Dialogs
                .alert("Confirm Upload", isPresented: $viewModel.showUploadAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Confirm") {
                        viewModel.isCheckingArticles = false
                        viewModel.showPathSelection = true
                    }
                } message: {
                    Text("Do you want to upload this file?")
                }
                .confirmationDialog(
                    "Select Upload Path",
                    isPresented: $viewModel.showPathSelection,
                    titleVisibility: .visible
                ) {
                    // Predefined paths
                    ForEach(predefinedPaths, id: \.self) { path in
                        Button(path) {
                            if viewModel.isCheckingArticles {
                                viewModel.fetchArticles(from: path)
                            } else {
                                viewModel.uploadContent(path: path)
                            }
                        }
                    }
                    
                    // Additional options
                    Button("Custom Path") {
                        viewModel.showCustomPathInput = true
                        viewModel.customPathIsForArticles = viewModel.isCheckingArticles
                    }
                    
                    Button("Default (content)") {
                        if viewModel.isCheckingArticles {
                            viewModel.fetchArticles(from: "/content")
                        } else {
                            viewModel.uploadContent(path: "/content")
                        }
                    }
                    
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Choose or enter a path (default: content)")
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
        }
        .environmentObject(settings)
    }
    
    // MARK: - View Components
    private var toolbarButton: some View {
        Group {
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
}

// MARK: - Preview
#Preview {
    ContentView()
}
