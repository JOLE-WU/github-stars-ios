import SwiftUI
import Foundation

/// 列表中的单行：头像 + 仓库名 + 描述 + 语言/Star/Fork 统计。
struct RepoRowView: View {
    let repo: Repo

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: repo.owner.avatarUrl)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color(.secondarySystemBackground)
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(repo.fullName)
                    .font(.headline)
                    .lineLimit(1)

                if let desc = repo.description, !desc.isEmpty {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 12) {
                    if let lang = repo.language {
                        Label(lang, systemImage: "circle.fill")
                    }
                    Label(repo.starsText, systemImage: "star.fill")
                    Label(repo.forksText, systemImage: "tuningfork")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}
