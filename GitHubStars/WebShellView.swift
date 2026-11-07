import SwiftUI
import UIKit
import WebKit

/// 网页壳的加载状态模型：用于驱动原生层的加载指示器与失败重试界面。
final class WebShellModel: ObservableObject {
    @Published var isLoading = true
    @Published var didFail = false
    @Published var failMessage = ""
}

/// 应用根视图：一个全屏的 WKWebView，加载托管在 GitHub Pages 上的网页应用。
///
/// 这样后续界面与功能的变更只需更新网页端（推送即自动发布），无需重新编译 IPA。
struct WebShellView: View {
    private let url = URL(string: "https://JOLE-WU.github.io/github-stars-ios/")!
    @StateObject private var model = WebShellModel()
    @State private var reloadID = 0

    var body: some View {
        ZStack {
            WebView(url: url, model: model)
                .ignoresSafeArea()
                .id(reloadID)

            if model.isLoading {
                ProgressView("网页加载中…")
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }

            if model.didFail {
                VStack(spacing: 14) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text(model.failMessage)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    Button("重试") {
                        reloadID += 1
                        model.didFail = false
                        model.isLoading = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }
}

/// 对 WKWebView 的 SwiftUI 封装。
struct WebView: UIViewRepresentable {
    let url: URL
    @ObservedObject var model: WebShellModel

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // 向网页注入能力标记：网页端据此知道「window.open 会被原生交给系统浏览器」，
        // 从而不再降级为应用内打开。注入时机必须早于页面脚本执行。
        let capability = WKUserScript(
            source: "window.sgitCanOpenExternal = true;",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(capability)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        model.isLoading = true
        model.didFail = false
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let model: WebShellModel

        init(model: WebShellModel) {
            self.model = model
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            model.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            model.isLoading = false
            model.didFail = false
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            model.isLoading = false
            model.didFail = true
            model.failMessage = "网页加载失败：\(error.localizedDescription)\n请检查网络后重试。"
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            model.isLoading = false
            model.didFail = true
            model.failMessage = "网页加载失败：\(error.localizedDescription)\n请检查网络后重试。"
        }

        // 网页调用 window.open(url, "_blank") 或点击 target="_blank" 时，
        // WKWebView 默认会静默丢弃请求。这里把 http/https 链接交给系统默认浏览器
        // （Safari 或用户设置的默认浏览器），SGit 页面本身保持不动，随时可切回。
        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            guard let url = navigationAction.request.url,
                  let scheme = url.scheme?.lowercased(),
                  scheme == "http" || scheme == "https" else {
                return nil
            }
            DispatchQueue.main.async {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            return nil
        }
    }
}
