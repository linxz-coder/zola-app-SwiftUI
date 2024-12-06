import SwiftUI

struct ContentView: View {
    
    @StateObject var viewModel = ContentViewModel()
    @Environment(\.softwareKeyboard) var softwareKeyboard
    
    let predefinedPaths = [
        "/content/blog",
        "/content/shorts",
        "/content/books"
    ]
    
    var body: some View {
        Form{
            Section(header: Text("Front Matter")) {
                TextField("Title", text:$viewModel.title)
                DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                TextField("Author", text: $viewModel.author)
            }
            
            Section(header: Text("Content")) {
                TextEditor(text: $viewModel.content)
                    .frame(height: 200)
            }
            
            Section(header: Text("Tags")) {
                ForEach(0..<3) { index in
                    if index == 0 || !viewModel.tags[index - 1].isEmpty {
                        TextField("Tag \(index + 1)", text: $viewModel.tags[index])
                    }
                }
            }
            
            Section{
                HStack(spacing: 30) {
                    Button("Upload to Zola"){
                        viewModel.showUploadAlert = true
                    } .buttonStyle(.borderedProminent)
                    Button("Source Text"){
                        viewModel.showSourceText = true
                    } .buttonStyle(.borderedProminent)
                }
            }.listRowBackground(Color.clear) //去掉section背景
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
        
        
        //buttons-path selection
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
        
        //keyboard button -  Done
        if softwareKeyboard?.isVisible == true {
            HStack {
                Spacer() // 将按钮推到最右侧
                Button("Done") {
                    softwareKeyboard?.dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .frame(height: 45) // 设置背景条的高度
        }
    }
}

#Preview {
    ContentView()
}
