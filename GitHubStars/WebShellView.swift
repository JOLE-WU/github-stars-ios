import SwiftUI
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
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
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

    final class Coordinator: NSObject, WKNavigationDelegate {
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
    }
}
