import SwiftUI

class ContentViewModel: ObservableObject {
    
    @Published var selectedArticleContent: ArticleContent?
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
    @Published var showArticlesList = false
    @Published var articles: [(title: String, path: String)] = []
    @Published var isCheckingArticles = false
    @Published var isLoading = false
    @Published var loadingError: String?
    @Published var customPathIsForArticles = false
    
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

extension ContentViewModel {
    func fetchArticles(from path: String) {
        print("Starting to fetch articles from: \(path)")
        isLoading = true
        loadingError = nil
        articles = []  // 清空现有文章列表
        
        GitHubService.shared.fetchContents(path: path) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let contents):
                    print("Successfully fetched \(contents.count) files")
                    let group = DispatchGroup()
                    var tempArticles: [(title: String, path: String)] = []
                    
                    for content in contents where content.name.hasSuffix(".md") {
                        group.enter()
                        GitHubService.shared.fetchFileContent(url: content.url) { fileResult in
                            defer { group.leave() }
                            
                            switch fileResult {
                            case .success(let fileContent):
                                if let title = GitHubService.shared.parseFrontMatter(from: fileContent) {
                                    print("Found article: \(title)")
                                    DispatchQueue.main.async {
                                        tempArticles.append((title: title, path: content.path))
                                    }
                                }
                            case .failure(let error):
                                print("Error fetching file content: \(error.localizedDescription)")
                            }
                        }
                    }
                    
                    group.notify(queue: .main) {
                        print("Finished processing all files. Found \(tempArticles.count) articles")
                        self.articles = tempArticles.sorted(by: { $0.title < $1.title })
                        self.selectedPath = path
                        self.showArticlesList = true
                    }
                    
                case .failure(let error):
                    print("Failed to fetch contents: \(error.localizedDescription)")
                    self.loadingError = error.localizedDescription
                }
            }
        }
    }
}

extension ContentViewModel {
    
    func fetchArticleContent(path: String, title: String) {
        isLoading = true
        
        // 构建文件的完整 URL
        let apiPath = "https://api.github.com/repos/\(UserSettings.shared.githubUsername)/\(UserSettings.shared.githubRepo)/contents/\(path)"
        
        guard let url = URL(string: apiPath) else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(UserSettings.shared.githubToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let data = data,
                   let content = try? JSONDecoder().decode(GitHubContent.self, from: data),
                   let encodedContent = content.content,
                   let decodedData = Data(base64Encoded: encodedContent.replacingOccurrences(of: "\n", with: "")),
                   let decodedString = String(data: decodedData, encoding: .utf8) {
                    // 移除 front matter
                    let cleanContent = self.removeFrontMatter(from: decodedString)
                    self.selectedArticleContent = ArticleContent(title: title, content: cleanContent)
                }
            }
        }.resume()
    }
    
    private func removeFrontMatter(from content: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        var newContent: [String] = []
        var isFrontMatter = false
        var frontMatterDelimiter = "---"
        
        // 检查第一行来确定分隔符类型
        if let firstLine = lines.first?.trimmingCharacters(in: .whitespaces),
           firstLine == "+++" {
            frontMatterDelimiter = "+++"
        }
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine == frontMatterDelimiter {
                if !isFrontMatter {
                    isFrontMatter = true
                    continue
                } else {
                    isFrontMatter = false
                    continue
                }
            }
            if !isFrontMatter {
                newContent.append(line)
            }
        }
        
        return newContent.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
