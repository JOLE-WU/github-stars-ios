import SwiftUI

/// 设置页：可选配置 GitHub Personal Access Token，以提升 API 速率限制。
struct SettingsView: View {
    @AppStorage("github_token") private var storedToken: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Personal Access Token", text: $text)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } header: {
                    Text("GitHub 访问令牌（可选）")
                } footer: {
                    Text("未登录时 GitHub API 每小时仅 60 次请求；填入 Token 可提升到 5000 次。仅需具备 public_repo 只读权限的 Token 即可。")
                }

                Section {
                    Button("保存") {
                        storedToken = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)

                    Button("清除令牌", role: .destructive) {
                        storedToken = ""
                        text = ""
                        dismiss()
                    }
                }
            }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear { text = storedToken }
        }
    }
}
