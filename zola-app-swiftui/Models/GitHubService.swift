import Foundation

class GitHubService {
    static let shared = GitHubService()
    private let branch = "main"
    
    func uploadContent(content: String, filename: String, path: String = "content/blog", completion: @escaping (Result<Void, Error>) -> Void) {
        let settings = UserSettings.shared
        guard settings.isConfigured else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "GitHub settings not configured"])))
            return
        }
        
        let endpoint = "https://api.github.com/repos/\(settings.githubUsername)/\(settings.githubRepo)/contents/\(path)/\(filename)"
        
        guard let url = URL(string: endpoint),
              let contentData = content.data(using: .utf8) else {
            completion(.failure(NSError(domain: "", code: -1)))
            return
        }
        
        let base64Content = contentData.base64EncodedString()
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(settings.githubToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "message": "Add new blog post",
            "content": base64Content,
            "branch": branch
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                completion(.success(()))
            } else {
                if let data = data,
                   let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorMessage["message"] as? String {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: message])))
                } else {
                    completion(.failure(NSError(domain: "", code: -1)))
                }
            }
        }.resume()
    }
}
