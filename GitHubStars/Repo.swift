import Foundation

/// GitHub 搜索接口返回的顶层结构（search/repositories）。
struct SearchResponse: Codable {
    let totalCount: Int
    let incompleteResults: Bool
    let items: [Repo]
}

/// 单个仓库模型，字段与 GitHub API 的 snake_case 键通过 convertFromSnakeCase 自动映射。
struct Repo: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let fullName: String
    let htmlUrl: String
    let description: String?
    let stargazersCount: Int
    let forksCount: Int
    let watchersCount: Int
    let language: String?
    let owner: Owner
    let updatedAt: String?

    struct Owner: Codable, Hashable {
        let login: String
        let avatarUrl: String
        let htmlUrl: String
    }

    /// 把较大的数字格式化为 "12.3k" 形式，便于在列表行内展示。
    var starsText: String { formatCount(stargazersCount) }
    var forksText: String { formatCount(forksCount) }
}

/// 将 1000+ 的数字格式化为带 k 的紧凑字符串。
func formatCount(_ n: Int) -> String {
    if n >= 1000 {
        let d = Double(n) / 1000.0
        return String(format: "%.1fk", d)
    }
    return "\(n)"
}
