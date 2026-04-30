import Foundation
import Network

setbuf(stdout, nil)

let port: NWEndpoint.Port = .init(
  rawValue: UInt16(ProcessInfo.processInfo.environment["SPIKE_STUB_PORT"] ?? "7717") ?? 7717,
)!

let allowlist: Set<String> = [
  "wikipedia.org",
  "github.com",
  "news.ycombinator.com",
  "example.com",
  "example.org",
]

let injectedDelayMs: Int = .init(
  ProcessInfo.processInfo.environment["SPIKE_STUB_DELAY_MS"] ?? "0",
) ?? 0

func permits(_ host: String) -> Bool {
  let h = host.lowercased()
  if allowlist.contains(h) { return true }
  return allowlist.contains(where: { h.hasSuffix("." + $0) })
}

func reply(allow: Bool, reason: String, conn: NWConnection) {
  let body = "{\"allow\":\(allow),\"reason\":\"\(reason)\"}"
  let response = """
  HTTP/1.1 200 OK\r
  Content-Type: application/json\r
  Content-Length: \(body.utf8.count)\r
  Connection: close\r
  \r
  \(body)
  """
  conn.send(
    content: response.data(using: .utf8),
    completion: .contentProcessed { _ in conn.cancel() },
  )
}

func handle(_ conn: NWConnection) {
  conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, _, _ in
    guard let data, let request = String(data: data, encoding: .utf8) else {
      conn.cancel()
      return
    }
    let firstLine = request.components(separatedBy: "\r\n").first ?? ""
    let parts = firstLine.split(separator: " ")
    guard parts.count >= 2 else { conn.cancel()
      return
    }
    let path = String(parts[1])
    guard let comps = URLComponents(string: "http://stub\(path)") else {
      reply(allow: false, reason: "bad path", conn: conn)
      return
    }
    let host = comps.queryItems?.first(where: { $0.name == "host" })?.value ?? ""
    let kind = comps.queryItems?.first(where: { $0.name == "kind" })?.value ?? "?"
    let allow = host.isEmpty ? true : permits(host)
    let reason = allow ? "allowed" : "host '\(host)' not in stub allowlist"
    print("[stub] req kind=\(kind) host=\(host) → \(allow ? "ALLOW" : "BLOCK")")

    if injectedDelayMs > 0 {
      let deadline = DispatchTime.now() + .milliseconds(injectedDelayMs)
      DispatchQueue.global().asyncAfter(deadline: deadline) {
        reply(allow: allow, reason: reason, conn: conn)
      }
    } else {
      reply(allow: allow, reason: reason, conn: conn)
    }
  }
}

let listener: NWListener
do {
  listener = try NWListener(using: .tcp, on: port)
} catch {
  print("[stub] failed to listen on \(port): \(error)")
  exit(1)
}

listener.newConnectionHandler = { conn in
  conn.start(queue: .main)
  handle(conn)
}

listener.start(queue: .main)
print("[stub] policy stub listening on 127.0.0.1:\(port.rawValue) delay=\(injectedDelayMs)ms")

RunLoop.main.run()
