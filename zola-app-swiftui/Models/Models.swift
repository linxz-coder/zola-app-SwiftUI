import Foundation

struct GitHubContent: Codable {
    let name: String
    let path: String
    let sha: String
    let size: Int
    let url: String
    let html_url: String
    let git_url: String
    let download_url: String?
    let type: String
    let content: String?
    let encoding: String?
    let _links: Links
    
    struct Links: Codable {
        let `self`: String
        let git: String
        let html: String
    }
}

struct ArticleContent: Identifiable {
    let id = UUID()
    let title: String
    let content: String
}
