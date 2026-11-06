import SwiftUI
import Foundation

/// 列表中的单个卡片：头像 + 仓库名 + 拥有者 + 描述 + 语言/Star/Fork 统计。
struct RepoRowView: View {
    let repo: Repo

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: repo.owner.avatarUrl)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color(.secondarySystemBackground)
                }
                .frame(width: 42, height: 42)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(repo.fullName)
                        .font(.headline)
                        .lineLimit(1)
                    Text("由 \(repo.owner.login) 创建")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            if let desc = repo.description, !desc.isEmpty {
                Text(desc)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            HStack(spacing: 16) {
                if let lang = repo.language {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(languageColor(lang))
                            .frame(width: 9, height: 9)
                        Text(lang)
                    }
                }
                Label(repo.starsText, systemImage: "star.fill")
                    .foregroundStyle(.orange)
                Label(repo.forksText, systemImage: "tuningfork")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.separator).opacity(0.4), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}
