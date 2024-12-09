// Views.swift
import SwiftUI
import WebKit
import Down


struct ArticleDetailView: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    let content: String
    
    private var htmlContent: String {
        let down = Down(markdownString: content)
        return (try? down.toHTML()) ?? ""
    }
    
    var body: some View {
        NavigationView {
            MarkdownWebView(htmlContent: htmlContent)
                            .navigationTitle(title)
                            .navigationBarItems(trailing: Button("Done") {
                                dismiss()
                            })
            }
    }
}

struct ArticlesListView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading articles...")
                } else if let error = viewModel.loadingError {
                    VStack {
                        Text("Error loading articles")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if viewModel.articles.isEmpty {
                    Text("No articles found in this path")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        ForEach(viewModel.articles, id: \.path) { article in
                            VStack(alignment: .leading) {
                                Text(article.title)
                                    .font(.headline)
                                Text(article.path)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.fetchArticleContent(path: article.path, title: article.title)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Articles in \(viewModel.selectedPath)")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
        .sheet(item: $viewModel.selectedArticleContent) { article in
            ArticleDetailView(title: article.title, content: article.content)
        }
    }
}

struct MarkdownWebView: UIViewRepresentable {
    let htmlContent: String
    
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = true
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body {
                    font-family: -apple-system, system-ui;
                    font-size: 16px;
                    line-height: 1.5;
                    padding: 15px;
                    margin: 0;
                }
                img {
                    max-width: 100%;
                    height: auto;
                    border-radius: 8px;
                }
                pre {
                    background-color: #f5f5f5;
                    padding: 10px;
                    border-radius: 8px;
                    overflow-x: auto;
                }
                code {
                    font-family: Monaco, monospace;
                }
                blockquote {
                    border-left: 4px solid #ddd;
                    margin: 0;
                    padding-left: 16px;
                    color: #666;
                }
                @media (prefers-color-scheme: dark) {
                    body {
                        background-color: #000;
                        color: #fff;
                    }
                    pre {
                        background-color: #1a1a1a;
                    }
                    blockquote {
                        border-left-color: #444;
                        color: #999;
                    }
                }
            </style>
        </head>
        <body>
            \(htmlContent)
        </body>
        </html>
        """
        
        webView.loadHTMLString(htmlString, baseURL: nil)
    }
}

