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
}
