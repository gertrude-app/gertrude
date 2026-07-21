import ComposableArchitecture
import SwiftUI
import WebKit

struct TabContentView: View {
  let store: StoreOf<Tab>

  var body: some View {
    WithPerceptionTracking {
      WebView(url: self.store.url)
    }
  }
}

#if os(macOS)
  struct WebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
      WKWebView()
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
      if webView.url != self.url {
        webView.load(URLRequest(url: self.url))
      }
    }
  }

#elseif os(iOS)
  struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
      WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
      if webView.url != self.url {
        webView.load(URLRequest(url: self.url))
      }
    }
  }
#endif
