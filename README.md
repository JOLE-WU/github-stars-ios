# GitHub 高星项目（iOS）

一个用 **SwiftUI** 编写的 iOS App，用于获取并展示 GitHub 上的高星（Star 数高）开源项目。

> 说明：本项目在 Linux 沙箱中生成，无法直接编译运行。请在 **macOS + Xcode 15+** 中打开 `GitHubStars.xcodeproj` 构建。代码为标准 SwiftUI 写法，已按 iOS 16 适配。

## 功能特性

| 功能 | 说明 |
| --- | --- |
| 高星榜单 | 默认展示全站 Star 数最高的仓库（按 stars 降序） |
| 关键字搜索 | 顶部搜索框按关键字搜索，结果仍以热度（Star）排序 |
| 语言筛选 | 右上角菜单按语言过滤（Swift / Python / JavaScript / Go / Rust 等） |
| 下拉刷新 | 下拉即可重新拉取 |
| 无限滚动 | 滚动到底部自动分页加载更多 |
| 项目详情 | 头像、描述、Star / Fork / Watchers 统计，一键跳转 GitHub |
| 访问令牌 | 设置页可填写 GitHub Token，将速率限制从 60 次/小时提升到 5000 次/小时 |

## 运行方式

1. 在 Mac 上安装 Xcode 15 或更高版本。
2. 双击打开仓库根目录下的 `GitHubStars.xcodeproj`。
3. 选择模拟器（如 iPhone 15）或真机，点击运行（⌘R）。

> 若 Xcode 提示签名问题：进入 `TARGETS → GitHubStars → Signing & Capabilities`，把 **Bundle Identifier** 改成你自己的（例如 `com.yourname.GitHubStars`），并选择你的开发团队即可。

## API 说明

数据来自 GitHub 官方 REST API 的搜索接口：

```
GET https://api.github.com/search/repositories?q=stars:>1&sort=stars&order=desc
```

未登录状态下该接口每小时限 60 次请求。如需更高额度，在 App 内「设置」填入一个具备 `public_repo` 只读权限的 Personal Access Token 即可。

## 项目结构

```
GitHubStars/
├── GitHubStars.xcodeproj/        # Xcode 工程文件
├── README.md
└── GitHubStars/
    ├── GitHubStarsApp.swift      # @main 入口
    ├── Repo.swift                # 数据模型（Codable）
    ├── GitHubService.swift       # GitHub API 服务层（async/await）
    ├── RepoListView.swift        # 主列表：搜索 / 筛选 / 刷新 / 分页
    ├── RepoRowView.swift         # 列表行
    ├── RepoDetailView.swift      # 详情页
    ├── SettingsView.swift        # Token 设置页
    ├── Assets.xcassets/          # 图标与配色
    └── Info.plist
```

## 可扩展方向

- 增加「本周 / 本月 Trending」时间维度筛选（`created:>YYYY-MM-DD`）。
- 收藏功能（本地 Core Data / SwiftData 持久化）。
- 深色模式与主题色细化。
- 增加仓库 README 预览。

## CI 自动构建（GitHub Actions）

仓库已配置 `.github/workflows/build.yml`：每次推送到 `main` 或手动触发时，会在 macOS runner 上用 Xcode 编译并打包出 **未签名 IPA** 作为可下载产物（仓库 → Actions → 对应运行 → Artifacts）。

> 未签名 IPA 不能直接装到真机，它用于**验证编译通过**，以及供你在本地用免费 Apple ID 重新签名。

## 用免费 Apple ID 把 App 装到 iPhone

免费账号无法在 CI 直接签出可安装 IPA（免费描述文件与 Mac 绑定），需在 Mac 上完成签名侧载：

1. Mac 打开本工程，Xcode 登录你的 Apple ID（`Settings → Accounts`）。
2. 连接真机，签名 Team 选你的个人账号，Xcode 会自动生成免费描述文件。
3. ⌘R 运行即安装到手机（免费签名有效期 7 天，到期需重连 Mac 刷新）。
4. 或不走 Xcode：用 **AltStore / Sideloadly** 对从 Actions 下载的未签名 IPA，用你的 Apple ID 重新签名后安装。

> 若后续升级为付费开发者账号（$99/年），可在 Actions 中配置证书 / 描述文件 Secrets，把工作流改为正式签名并走 TestFlight / AdHoc 分发。
