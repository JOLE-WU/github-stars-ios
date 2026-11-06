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

/// 各编程语言对应的主题色（用于列表/卡片上的语言圆点）。
func languageColor(_ language: String) -> Color {
    let map: [String: Color] = [
        "Swift": Color(hex: 0xF05138),
        "Python": Color(hex: 0x3572A5),
        "JavaScript": Color(hex: 0xF1E05A),
        "TypeScript": Color(hex: 0x3178C6),
        "Go": Color(hex: 0x00ADD8),
        "Rust": Color(hex: 0xDEA584),
        "Java": Color(hex: 0xB07219),
        "C++": Color(hex: 0xF34B7D),
        "C": Color(hex: 0x555555),
        "C#": Color(hex: 0x178600),
        "Ruby": Color(hex: 0x701516),
        "Kotlin": Color(hex: 0xA97BFF),
        "PHP": Color(hex: 0x4F5D95),
        "Shell": Color(hex: 0x89E051),
        "Dart": Color(hex: 0x00B4AB),
        "Vue": Color(hex: 0x41B883),
        "HTML": Color(hex: 0xE34C26)
    ]
    return map[language] ?? Color(hex: 0x8E8E93)
}

extension Color {
    /// 通过十六进制整数构造颜色，例如 0xF05138。
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
