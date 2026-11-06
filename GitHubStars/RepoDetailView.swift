import SwiftUI
import Foundation

/// 仓库详情页：展示所有者、描述、Star/Fork/Watchers 统计，并支持跳转到 GitHub。
struct RepoDetailView: View {
    let repo: Repo

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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
                        Text("by \(repo.owner.login)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if let desc = repo.description, !desc.isEmpty {
                    Text(desc)
                        .font(.body)
                }

                HStack(spacing: 12) {
                    StatCard(title: "Stars", value: "\(repo.stargazersCount)")
                    StatCard(title: "Forks", value: "\(repo.forksCount)")
                    StatCard(title: "Watchers", value: "\(repo.watchersCount)")
                }

                if let lang = repo.language {
                    Label(lang, systemImage: "circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

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
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
