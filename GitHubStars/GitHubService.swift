import Foundation

/// 负责与 GitHub REST API 交互的服务层。
///
/// 使用 Swift 并发（async/await）封装网络请求；支持：
/// - 按 star 数量降序搜索仓库
/// - 分页加载
/// - 可选的个人访问令牌（提升速率限制）
actor GitHubService {

    static let shared = GitHubService()

    private let baseURL = "https://api.github.com"
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = 20
        self.session = URLSession(configuration: config)
    }

    /// 读取用户在设置页保存的访问令牌（保存在 UserDefaults）。
    private var accessToken: String? {
        let token = UserDefaults.standard.string(forKey: "github_token") ?? ""
        return token.isEmpty ? nil : token
    }

    /// 搜索仓库，结果按 star 数降序排列。
    /// - Parameters:
    ///   - query: 完整的 GitHub 搜索表达式，例如 "stars:>1" 或 "tensorflow language:Python"。
    ///   - page: 页码，从 1 开始。
    ///   - perPage: 每页数量，默认 30。
    func search(query: String, page: Int = 1, perPage: Int = 30) async throws -> [Repo] {
        var components = URLComponents(string: "\(baseURL)/search/repositories")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "sort", value: "stars"),
            URLQueryItem(name: "order", value: "desc"),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)")
        ]

        guard let url = components.url else { throw ServiceError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("GitHubStars-iOS-App", forHTTPHeaderField: "User-Agent")
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }

        switch http.statusCode {
        case 200...299:
            break
        case 403, 429:
            throw ServiceError.rateLimited
        default:
            throw ServiceError.httpError(http.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        do {
            let result = try decoder.decode(SearchResponse.self, from: data)
            return result.items
        } catch {
            throw ServiceError.decodingFailed(error.localizedDescription)
        }
    }
}

enum ServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case rateLimited
    case httpError(Int)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的请求地址"
        case .invalidResponse:
            return "收到了无效的服务器响应"
        case .rateLimited:
            return "请求过于频繁，已被限流。未登录每小时仅 60 次，可在「设置」中填入 Token 提升到 5000 次。"
        case .httpError(let code):
            return "服务器返回错误（HTTP \(code)）"
        case .decodingFailed(let detail):
            return "数据解析失败：\(detail)"
        }
    }
}
