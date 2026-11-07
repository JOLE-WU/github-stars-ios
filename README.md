# SGit（iOS）

**SGit** 是一个 iOS App，用于获取并展示 GitHub 上的高星（Star 数高）开源项目。App 图标为黑色像素风「章鱼猫（Octocat）」，桌面显示名为 **SGit**。

> **架构**：原生 SwiftUI 仅作为一个 `WKWebView` 网页壳，真实界面与逻辑都运行在托管于 **GitHub Pages** 的网页（`index.html`）中。因此**后续界面/功能变更只需修改网页并推送**，GitHub Pages 会自动发布，无需重新编译 IPA、也不消耗 Actions 构建额度。

> 说明：本项目在 Linux 沙箱中生成，无法直接编译运行。请在 **macOS + Xcode 15+** 中打开 `GitHubStars.xcodeproj` 构建。只有**首次**需要构建 IPA（把网页壳打进 App），之后改网页即可。

## 功能特性

| 功能 | 说明 |
| --- | --- |
| 卡片样式 | 每个项目以圆角阴影卡片呈现（头像 / 名称 / 拥有者 / 描述 / 语言 / Star / Fork） |
| 高星榜单 | 默认展示全站 Star 数最高的仓库（按 stars 降序） |
| 升星最快板块 | 按「近 30 天创建 + Star 降序」展示近期增长最快的项目 |
| 横向分类 | 顶部横向滚动的语言分类标签（Swift / Python / Go / Rust 等），点击即时筛选 |
| 底部搜索栏 | 固定在底部的搜索框，按关键字搜索，结果仍以热度（Star）排序 |
| 用户中心 | 底部搜索栏右侧的**用户头像**按钮，点击打开「我的」二级页 |
| 登录 / 注册 | 纯本地账号（用户名 + 密码，仅存本机、不上传），登录后头像显示用户名首字母 |
| 收藏管理 | 登录后可在卡片 / 详情页点 ☆ 收藏，在「我的 → 我的收藏」中查看、打开详情、移除；按账号隔离 |
| 设置（原齿轮） | 原顶部「齿轮 / 令牌」设置已整体并入「我的」页：GitHub Token、Cloudflare 翻译端点、翻译开关、刷新列表、**刷新网页（获取新版）**（强制拉取最新网页，绕过 App 缓存，无需重装 IPA） |
| 下拉刷新 / 无限滚动 | 刷新按钮 + 滚动到底部自动分页加载 |
| 项目详情 | 弹层明细列表，逐项列出全称 / 拥有者 / 语言 / 星标 / 派生 / 关注 / 开放 Issue / 创建与更新时间 / 开源协议 / 主题标签 / 主页，并一键跳转 GitHub |
| 外部链接 | 「项目主页」「GitHub 地址」「在 GitHub 中打开」均可点击，旁边有「复制」按钮。App 内点击弹出确认层：**应用内打开**（在带「← 返回 SGit」按钮的应用内浏览器层中显示，主页面不被导航走，随时可返回；另有后退、刷新、复制地址、用 Safari 打开）或**复制地址**。GitHub 等站点设置了不允许内嵌，若内容区显示空白，请复制地址到 Safari 打开。网页中点击则在浏览器新标签打开 |
| 描述翻译 | 默认开启，自动把仓库英文描述翻译成中文；详情页与每张卡片均可「看原文 / 看译文」切换。内置 **Google + MyMemory** 两个免 key 公共端点自动兜底；并支持在「我的 → 设置」填入**自建 Cloudflare Workers AI 翻译端点**，在国内稳定翻译、不受公共端点限流影响 |
| 访问令牌 | 「我的 → 设置」可填写 GitHub Token，将速率限制从 60 次/小时提升到 5000 次/小时（仅存于本机浏览器） |

> 说明：「登录 / 注册 / 收藏」为**纯前端本地实现**（数据存在 App 的 `localStorage`，不联网、不跨设备同步），用于演示产品形态；若需要真正的账号系统与云端收藏，需接入后端服务。

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

未登录状态下该接口每小时限 60 次请求。如需更高额度，在「我的 → 设置」填入一个具备 `public_repo` 只读权限的 Personal Access Token 即可。

## 项目结构

```
GitHubStars/
├── GitHubStars.xcodeproj/        # Xcode 工程文件（仅含网页壳）
├── index.html                    # 网页应用本体（界面与逻辑都在这里，托管到 GitHub Pages）
├── README.md
└── GitHubStars/
    ├── GitHubStarsApp.swift      # @main 入口
    ├── WebShellView.swift        # WKWebView 网页壳（加载上面的 index.html）
    ├── Info.plist                # 桌面显示名 SGit + 图标声明
    ├── Assets.xcassets/AppIcon.appiconset/AppIcon.png   # SGit 图标
    └── （其余 SwiftUI 视图为历史实现，已不再作为主界面使用）
└── cloudflare/
    ├── worker.js                  # 自建翻译服务（Cloudflare Workers AI）
    └── wrangler.toml              # Worker 部署配置
```

> 注意：App 的实际功能 100% 在 `index.html` 里。改界面/功能请改 `index.html`，不要改 Swift 代码（除非要改壳本身）。

## 可扩展方向

- 增加「本周 / 本月 Trending」时间维度筛选（`created:>YYYY-MM-DD`）。
- 云端账号与跨设备收藏同步（需接入后端）。
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

## 自建翻译服务（国内稳定翻译，可选）

公共翻译端点（Google、MyMemory）在国内可能被墙或每日限流。仓库内置了基于 **Cloudflare Workers AI**（Meta 开源模型 `@cf/meta/m2m100-1.2b`）的翻译 Worker，免费、国内可直连、设备端无需下载模型。

### 部署步骤（约 3 分钟，免费）

1. 注册免费 Cloudflare 账号：https://dash.cloudflare.com/sign-up
2. 安装并登录 Wrangler：`npm install -g wrangler && wrangler login`
3. 部署本仓库 `cloudflare/` 目录下的 Worker：
   ```bash
   cd cloudflare
   wrangler deploy
   ```
4. 终端会输出你的端点地址，形如 `https://gh-stars-translate.<你的子域>.workers.dev`
5. 在 App 底部头像 →「我的 → 设置」里，把该地址填到 **Cloudflare 翻译端点** 一栏并保存。

之后 App 会优先使用你自己的翻译服务，国内稳定可用，且不受公共端点限流影响。

### 原理与额度

- Worker 代码：`cloudflare/worker.js`，接收 `POST {text}`，返回 `{translatedText}`，并带 CORS 头供网页调用。
- 免费额度 **10,000 神经元/天**（约数百条翻译），超出后自动回退到 Google / MyMemory。
- 翻译失败/超时会回退显示原文，不会让 App 崩溃。
- **失败结果不写入缓存**：翻译成功后才缓存译文，失败下次会自动重试；App 启动时也会自动清理旧版遗留的「失败缓存」。

### 翻译排障

在 App「我的 → 设置」里点 **「测试翻译」**，会逐个端点实测并把成功/失败原因直接显示出来：

| 诊断输出 | 含义与处理 |
| --- | --- |
| `#1 ✅ 译文：…` | 自建 Worker 正常，翻译已恢复 |
| `#1 ❌ … AI binding missing` | `wrangler.toml` 缺 `[ai] binding = "AI"`，重新 `wrangler deploy` |
| `#1 ❌ … target_lang=… → …` | Workers AI 模型调用报错，确认账号已启用 Workers AI，并重新部署最新版 `worker.js` |
| `#1 ❌ 超时 / 请求失败` | 当前网络连不上 `workers.dev`，换网络或稍后重试 |
| 全部 ❌ | 公共端点在国内也不可用；等 MyMemory 次日额度重置，或修好自建 Worker |

也可在浏览器直接打开 `https://xxx.workers.dev`，返回 JSON 里 `ai_binding` 应为 `true`。
若曾翻译失败过，可点 **「清除翻译缓存」** 后刷新列表强制重试。
