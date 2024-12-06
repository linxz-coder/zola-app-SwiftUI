import SwiftUI

class ContentViewModel: ObservableObject {
    @Published var title = ""
    @Published var date = Date()
    @Published var author = "小中"
    @Published var content = ""
    @Published var tags: [String] = ["", "", ""]
    @Published var showSourceText = false
    @Published var showUploadAlert = false
    @Published var showPathSelection = false
    @Published var showCustomPathInput = false
    @Published var customPath = "/content/"
    @Published var selectedPath = ""
    @Published var alertMessage = ""
    @Published var showAlert = false
    
    var structuredText: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.string(from: date)
        
        // Filter out empty tags
        let validTags = tags.filter { !$0.isEmpty }
        let taxonomySection = validTags.isEmpty ? "" : """
            [taxonomies]
            tags = ["\(validTags.joined(separator: "\", \""))"]
            
            """
        
        return """
        +++
        title = "\(title)"
        date = \(formattedDate)
        authors = ["\(author)"]
        \(taxonomySection)
        +++
        
        \(content)
        
        """
    }
    
    func resetForm() {
        title = ""
        date = Date()
        //author = "" // Keeping author as per original code
        content = ""
        tags = ["", "", ""]
    }
    
    func uploadContent(path: String) {
        guard !title.isEmpty else { return }
        
        // Remove leading slash if present
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        
        GitHubService.shared.uploadContent(
            content: structuredText,
            filename: "\(title).md",
            path: cleanPath
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.alertMessage = "Successfully uploaded to \(path)!"
                    self?.showAlert = true
                    self?.resetForm()
                case .failure(let error):
                    self?.alertMessage = "Upload failed: \(error.localizedDescription)"
                    self?.showAlert = true
                }
            }
        }
    }
}
