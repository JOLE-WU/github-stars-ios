import SwiftUI
import Foundation

/// 仓库详情页：以卡片 + 明细列表的形式，把项目的各项信息用中文逐项列举出来。
struct RepoDetailView: View {
    let repo: Repo

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 头部卡片：头像 + 名称 + 拥有者
                HStack(spacing: 14) {
                    AsyncImage(url: URL(string: repo.owner.avatarUrl)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color(.secondarySystemBackground)
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(repo.fullName)
                            .font(.title3).bold()
                            .lineLimit(2)
                        Text("由 \(repo.owner.login) 创建")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // 项目描述
                if let desc = repo.description, !desc.isEmpty {
                    Text(desc)
                        .font(.body)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // 数据统计（网格）
                LazyVGrid(columns: [
                    GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
                ], spacing: 12) {
                    StatCard(title: "星标", value: repo.starsText)
                    StatCard(title: "派生", value: repo.forksText)
                    StatCard(title: "关注", value: "\(repo.watchersCount)")
                    StatCard(title: "开放 Issue", value: "\(repo.openIssuesCount ?? 0)")
                }

                // 详细信息列表
                VStack(alignment: .leading, spacing: 0) {
                    DetailRow("项目全称", repo.fullName)
                    DetailRow("拥有者", repo.owner.login)
                    if let lang = repo.language {
                        DetailRow("主要语言", lang, color: languageColor(lang))
                    }
                    if let lic = repo.licenseText {
                        DetailRow("开源协议", lic)
                    }
                    if let created = repo.createdDateText {
                        DetailRow("创建时间", created)
                    }
                    if let updated = repo.updatedDateText {
                        DetailRow("最近更新", updated)
                    }
                    if let size = repo.size {
                        DetailRow("仓库大小", "\(size) KB")
                    }
                    if let topics = repo.topics, !topics.isEmpty {
                        DetailRow("主题标签", topics.joined(separator: "、"))
                    }
                    if let homepage = repo.homepage, !homepage.isEmpty {
                        DetailRow("项目主页", homepage)
                    }
                    DetailRow("GitHub 地址", repo.htmlUrl, isLink: true)
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // 跳转 GitHub
                if let url = URL(string: repo.htmlUrl) {
                    Link(destination: url) {
                        Label("在 GitHub 中打开", systemImage: "safari")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .navigationTitle("项目详情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 详情页中用于展示单个统计项的卡片。
struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.headline)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// 详情页中用于展示「标签 + 值」的单行明细。
struct DetailRow: View {
    let label: String
    let value: String
    var color: Color?
    var isLink: Bool

    init(_ label: String, _ value: String, color: Color? = nil, isLink: Bool = false) {
        self.label = label
        self.value = value
        self.color = color
        self.isLink = isLink
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 76, alignment: .leading)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(isLink ? Color.accentColor : (color ?? Color.primary))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            Divider().padding(.leading, 16)
        }
    }
}
