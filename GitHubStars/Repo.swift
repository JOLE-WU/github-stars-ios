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
    let openIssuesCount: Int?
    let language: String?
    let owner: Owner
    let createdAt: String?
    let updatedAt: String?
    let pushedAt: String?
    let homepage: String?
    let license: License?
    let topics: [String]?
    let size: Int?

    struct Owner: Codable, Hashable {
        let login: String
        let avatarUrl: String
        let htmlUrl: String
    }

    struct License: Codable, Hashable {
        let name: String?
        let spdxId: String?
    }

    /// 把较大的数字格式化为 "12.3k" 形式，便于在列表行内展示。
    var starsText: String { formatCount(stargazersCount) }
    var forksText: String { formatCount(forksCount) }

    /// 创建时间（格式化为 yyyy-MM-dd）。
    var createdDateText: String? {
        guard let createdAt else { return nil }
        return formatISODate(createdAt)
    }

    /// 最近更新时间（格式化为 yyyy-MM-dd）。
    var updatedDateText: String? {
        guard let updatedAt else { return nil }
        return formatISODate(updatedAt)
    }

    /// 开源协议名称（优先展示 SPDX ID，再回退到完整名称）。
    var licenseText: String? {
        if let spdx = license?.spdxId, !spdx.isEmpty, spdx != "NOASSERTION" {
            return spdx
        }
        return license?.name
    }
}

/// 将 1000+ 的数字格式化为带 k 的紧凑字符串。
func formatCount(_ n: Int) -> String {
    if n >= 1000 {
        let d = Double(n) / 1000.0
        return String(format: "%.1fk", d)
    }
    return "\(n)"
}

/// 将 ISO8601 时间字符串（如 2021-01-02T03:04:05Z）格式化为 yyyy-MM-dd。
func formatISODate(_ iso: String) -> String {
    let fmt = ISO8601DateFormatter()
    guard let date = fmt.date(from: iso) else { return iso }
    let out = DateFormatter()
    out.dateFormat = "yyyy-MM-dd"
    out.locale = Locale(identifier: "zh_CN")
    return out.string(from: date)
}
