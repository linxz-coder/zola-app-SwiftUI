import Foundation

class UserSettings: ObservableObject {
    static let shared = UserSettings()
    
    @Published var githubUsername: String {
        didSet {
            UserDefaults.standard.set(githubUsername, forKey: "githubUsername")
        }
    }
    
    @Published var githubRepo: String {
        didSet {
            UserDefaults.standard.set(githubRepo, forKey: "githubRepo")
        }
    }
    
    @Published var githubToken: String {
        didSet {
            UserDefaults.standard.set(githubToken, forKey: "githubToken")
        }
    }
    
    init() {
        self.githubUsername = UserDefaults.standard.string(forKey: "githubUsername") ?? ""
        self.githubRepo = UserDefaults.standard.string(forKey: "githubRepo") ?? ""
        self.githubToken = UserDefaults.standard.string(forKey: "githubToken") ?? ""
    }
    
    var isConfigured: Bool {
        !githubUsername.isEmpty && !githubRepo.isEmpty && !githubToken.isEmpty
    }
}
