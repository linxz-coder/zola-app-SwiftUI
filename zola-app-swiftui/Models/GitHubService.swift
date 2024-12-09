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

extension GitHubService {
    func fetchContents(path: String, completion: @escaping (Result<[GitHubContent], Error>) -> Void) {
        let settings = UserSettings.shared
        guard settings.isConfigured else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "GitHub settings not configured"])))
            return
        }
        
        let sanitizedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let endpoint = "https://api.github.com/repos/\(settings.githubUsername)/\(settings.githubRepo)/contents/\(sanitizedPath)"
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(settings.githubToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let contents = try JSONDecoder().decode([GitHubContent].self, from: data)
                let mdFiles = contents.filter { $0.name.hasSuffix(".md") }
                print("Found \(mdFiles.count) markdown files")
                completion(.success(mdFiles))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchFileContent(url: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: url) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(UserSettings.shared.githubToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let content = try JSONDecoder().decode(GitHubContent.self, from: data)
                if let encodedContent = content.content,
                   let decodedData = Data(base64Encoded: encodedContent.replacingOccurrences(of: "\n", with: "")),
                   let decodedString = String(data: decodedData, encoding: .utf8) {
                    completion(.success(decodedString))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode content"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func parseFrontMatter(from content: String) -> String? {
        let lines = content.components(separatedBy: .newlines)
        var isFrontMatter = false
        var frontMatterLines: [String] = []
        var delimiter = "---"  // 默认分隔符
        
        // 检查第一行来确定分隔符类型
        if let firstLine = lines.first?.trimmingCharacters(in: .whitespaces) {
            if firstLine == "+++" {
                delimiter = "+++"
            }
        }
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine == delimiter {
                if !isFrontMatter {
                    isFrontMatter = true
                    continue
                } else {
                    break
                }
            }
            if isFrontMatter {
                frontMatterLines.append(line)
            }
        }
        
        for line in frontMatterLines {
            if line.contains("title") {
                // 处理 TOML 格式 (title = "value")
                if let range = line.range(of: #"title\s*=\s*[\""'](.+?)[\""']"#, options: .regularExpression) {
                    let matched = String(line[range])
                    let title = matched.replacingOccurrences(of: #"title\s*=\s*[\""']"#, with: "", options: .regularExpression)
                        .replacingOccurrences(of: #"[\""']$"#, with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespaces)
                    return title
                }
                // 处理 YAML 格式 (title: value)
                else if let range = line.range(of: #"title:\s*(.+)"#, options: .regularExpression) {
                    let matched = String(line[range])
                    let title = matched.replacingOccurrences(of: "title:", with: "")
                        .trimmingCharacters(in: .whitespaces)
                        .replacingOccurrences(of: "\"", with: "")
                        .replacingOccurrences(of: "'", with: "")
                    return title
                }
            }
        }
        
        return nil
    }
    
    
}
