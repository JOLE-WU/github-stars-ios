import SwiftUI

/// 榜单类型：高星榜（按 star 降序）或升星最快（近 30 天创建、按 star 降序）。
enum RankingType: String, CaseIterable, Identifiable {
    case hot = "高星榜"
    case trending = "升星最快"
    var id: String { rawValue }
}

/// 主界面：以卡片形式展示 GitHub 上的高星项目，并提供榜单切换与横向语言分类。
///
/// 功能：
/// - 两个榜单：高星榜（全站 star 最高）/ 升星最快（近 30 天创建且 star 最高）
/// - 顶部横向滚动的语言分类标签，点击即时筛选
/// - 默认展示全站 star 数最高的仓库
/// - 顶部搜索框按关键字搜索（仍按 star 排序）
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
    @State private var rankingType: RankingType = .hot
    @State private var showSettings = false

    /// 可筛选的语言列表；nil 表示「全部」。
    private let languages: [String?] = [
        nil, "Swift", "Python", "JavaScript", "TypeScript",
        "Go", "Rust", "Java", "C++", "C#", "Kotlin", "Ruby", "PHP", "Vue", "Dart"
    ]

    private let perPage = 30

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 榜单切换
                Picker("榜单", selection: $rankingType) {
                    ForEach(RankingType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 6)
                .onChange(of: rankingType) { _ in Task { await load(refresh: true) } }

                // 横向语言分类
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(languages, id: \.self) { lang in
                            languageChip(lang)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }

                content
            }
            .navigationTitle("GitHub 高星项目")
            .searchable(text: $searchText, prompt: "搜索仓库，按热度排序")
            .onSubmit(of: .search) { Task { await load(refresh: true) } }
            .refreshable { await load(refresh: true) }
            .task { await load(refresh: true) }
            .toolbar {
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

    /// 语言筛选标签。选中态高亮，未选中为灰色描边。
    private func languageChip(_ lang: String?) -> some View {
        let isSelected = languageFilter == lang
        let title = lang ?? "全部"
        return Button {
            languageFilter = lang
            Task { await load(refresh: true) }
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color(.separator), lineWidth: 0.5)
                )
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && repos.isEmpty {
            ProgressView("加载中…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = errorMessage, repos.isEmpty {
            errorView(message: errorMessage)
        } else {
            list
        }
    }

    /// 卡片流：ScrollView + LazyVStack，每行是一个 RepoRowView 卡片。
    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(repos) { repo in
                    NavigationLink {
                        RepoDetailView(repo: repo)
                    } label: {
                        RepoRowView(repo: repo)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if repo == repos.last {
                            Task { await loadMore() }
                        }
                    }
                }
                if isLoading && !repos.isEmpty {
                    ProgressView().padding()
                }
            }
            .padding()
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 查询构建与数据加载

    /// 近 30 天日期，用于「升星最快」板块（created:>=日期）。
    private var thirtyDaysAgo: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return fmt.string(from: date)
    }

    private func buildQuery() -> String {
        var parts: [String] = []
        let keyword = searchText.trimmingCharacters(in: .whitespaces)
        if keyword.isEmpty {
            if rankingType == .trending {
                parts.append("created:>=\(thirtyDaysAgo)")
            } else {
                parts.append("stars:>1")
            }
        } else {
            parts.append(keyword)
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
