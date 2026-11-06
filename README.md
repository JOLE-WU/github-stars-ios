# GitHub 高星项目（iOS）

一个 iOS App，用于获取并展示 GitHub 上的高星（Star 数高）开源项目。

> **架构**：原生 SwiftUI 仅作为一个 `WKWebView` 网页壳，真实界面与逻辑都运行在托管于 **GitHub Pages** 的网页（`index.html`）中。因此**后续界面/功能变更只需修改网页并推送**，GitHub Pages 会自动发布，无需重新编译 IPA、也不消耗 Actions 构建额度。

> 说明：本项目在 Linux 沙箱中生成，无法直接编译运行。请在 **macOS + Xcode 15+** 中打开 `GitHubStars.xcodeproj` 构建。只有**首次**需要构建 IPA（把网页壳打进 App），之后改网页即可。

## 功能特性

| 功能 | 说明 |
| --- | --- |
| 卡片样式 | 每个项目以圆角阴影卡片呈现（头像 / 名称 / 拥有者 / 描述 / 语言 / Star / Fork） |
| 高星榜单 | 默认展示全站 Star 数最高的仓库（按 stars 降序） |
| 升星最快板块 | 按「近 30 天创建 + Star 降序」展示近期增长最快的项目 |
| 横向分类 | 顶部横向滚动的语言分类标签（Swift / Python / Go / Rust 等），点击即时筛选 |
| 关键字搜索 | 顶部搜索框按关键字搜索，结果仍以热度（Star）排序 |
| 下拉刷新 / 无限滚动 | 刷新按钮 + 滚动到底部自动分页加载 |
| 项目详情 | 弹层明细列表，逐项列出全称 / 拥有者 / 语言 / 星标 / 派生 / 关注 / 开放 Issue / 创建与更新时间 / 开源协议 / 主题标签 / 主页，并一键跳转 GitHub |
| 描述翻译 | 开启「翻译描述」开关后可把仓库英文描述翻译成中文（基于免费 MyMemory 接口，失败回退原文）；也支持单条「翻译此描述」 |
| 访问令牌 | 网页内「令牌」入口可填写 GitHub Token，将速率限制从 60 次/小时提升到 5000 次/小时（仅存于本机浏览器） |

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
├── GitHubStars.xcodeproj/        # Xcode 工程文件（仅含网页壳）
├── index.html                    # 网页应用本体（界面与逻辑都在这里，托管到 GitHub Pages）
├── README.md
└── GitHubStars/
    ├── GitHubStarsApp.swift      # @main 入口
    ├── WebShellView.swift        # WKWebView 网页壳（加载上面的 index.html）
    └── （其余 SwiftUI 视图为历史实现，已不再作为主界面使用）
```

> 注意：App 的实际功能 100% 在 `index.html` 里。改界面/功能请改 `index.html`，不要改 Swift 代码（除非要改壳本身）。

## 可扩展方向

- 增加「本周 / 本月 Trending」时间维度筛选（`created:>YYYY-MM-DD`）。
- 收藏功能（本地 Core Data / SwiftData 持久化）。
- 深色模式与主题色细化。
- 增加仓库 README 预览。

## CI 自动构建（GitHub Actions）

仓库已配置 `.github/workflows/build.yml`，但做了**路径过滤**：

- 只有 `GitHubStars/**` 或 `GitHubStars.xcodeproj/**`（即 Swift / Xcode 工程文件）变动时，才会触发 macOS 构建并打包出 **未签名 IPA** 作为可下载产物（仓库 → Actions → 对应运行 → Artifacts）。
- **仅修改网页（`index.html` 等）不会触发 IPA 构建**，因此日常迭代零构建额度消耗。

> 未签名 IPA 不能直接装到真机，它用于**验证编译通过**，以及供你在本地用免费 Apple ID 重新签名。

## 如何只更新网页（不重编 IPA）

1. 修改仓库根目录的 `index.html`（界面、功能、文案都在这里）。
2. 推送（`git push`）到 `main`。
3. GitHub Pages 会自动重新发布（通常 1 分钟内生效），App 里的网页壳刷新后即显示新内容——**全程无需重新编译/下载 IPA**。

## 首次构建与安装（仅需一次）

1. 在 Mac 上用 Xcode 15+ 打开 `GitHubStars.xcodeproj`，登录你的 Apple ID，连真机 ⌘R 运行（免费签名，7 天有效）；或用 **AltStore / Sideloadly** 对从 Actions 下载的未签名 IPA 重新签名安装。
2. 网页壳加载的地址为 `https://JOLE-WU.github.io/github-stars-ios/`，需先在仓库 Settings → Pages 启用（分支 `main`、目录 `/`）。

> 若后续升级为付费开发者账号（$99/年），可在 Actions 中配置证书 / 描述文件 Secrets，把工作流改为正式签名并走 TestFlight / AdHoc 分发。
