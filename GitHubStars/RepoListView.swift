import SwiftUI

/// 主界面：以列表形式展示 GitHub 上的高星项目。
///
/// 功能：
/// - 默认展示全站 star 数最高的仓库
/// - 顶部搜索框按关键字搜索（仍按 star 排序）
/// - 右上角按语言筛选
/// - 下拉刷新、滚动到底部自动分页加载
/// - 右上角进入「设置」配置访问令牌
struct RepoListView: View {
    @State private var repos: [Repo] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var page = 1
    @State private var hasMore = true
    @State private var languageFilter: String?
    @State private var showSettings = false

    /// 可筛选的语言列表；nil 表示「全部」。
    private let languages: [String?] = [
        nil, "Swift", "Python", "JavaScript", "TypeScript",
        "Go", "Rust", "Java", "C++", "Ruby", "Kotlin"
    ]

    private let perPage = 30

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("GitHub 高星项目")
                .searchable(text: $searchText, prompt: "搜索仓库，按热度排序")
                .onSubmit(of: .search) { Task { await load(refresh: true) } }
                .refreshable { await load(refresh: true) }
                .task { await load(refresh: true) }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            ForEach(languages, id: \.self) { lang in
                                Button(lang ?? "全部语言") {
                                    languageFilter = lang
                                    Task { await load(refresh: true) }
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && repos.isEmpty {
            ProgressView("加载中…")
        } else if let errorMessage = errorMessage, repos.isEmpty {
            errorView(message: errorMessage)
        } else {
            list
        }
    }

    private var list: some View {
        List(repos) { repo in
            NavigationLink {
                RepoDetailView(repo: repo)
            } label: {
                RepoRowView(repo: repo)
            }
            .onAppear {
                if repo == repos.last {
                    Task { await loadMore() }
                }
            }
        }
        .listStyle(.plain)
        .overlay(alignment: .bottom) {
            if isLoading && !repos.isEmpty {
                ProgressView().padding(8).background(.ultraThinMaterial, in: Capsule())
            }
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("重试") { Task { await load(refresh: true) } }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - 数据加载

    private func buildQuery() -> String {
        var parts: [String] = []
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            parts.append("stars:>1")
        } else {
            parts.append(searchText)
        }
        if let lang = languageFilter {
            parts.append("language:\(lang)")
        }
        return parts.joined(separator: " ")
    }

    private func load(refresh: Bool) async {
        if refresh {
            page = 1
            hasMore = true
        }
        await fetch(page: page)
    }

    private func loadMore() async {
        guard hasMore, !isLoading else { return }
        page += 1
        await fetch(page: page)
    }

    private func fetch(page: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await GitHubService.shared.search(
                query: buildQuery(), page: page, perPage: perPage
            )
            if page == 1 {
                repos = result
            } else {
                repos.append(contentsOf: result)
            }
            hasMore = result.count == perPage
        } catch {
            if page == 1 {
                errorMessage = (error as? LocalizedError)?.errorDescription
                    ?? error.localizedDescription
            }
        }
        isLoading = false
    }
}
