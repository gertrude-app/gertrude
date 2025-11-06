import ComposableArchitecture
import Foundation
import os.log
import SQLiteData

extension AddShowFeature {
  func handleSpecialAction(input: String) -> Effect<Action>? {
    if input == "am: change pin" {
      return .send(.setScreen(.changePinInstructions))
    }

    if input == "am: upload db" {
      return .run { send in
        guard let installId = self.keychain.loadInstallId() else { return }
        // can't just upload current file, data might be in WAL, so export
        let queue = try DatabaseQueue(path: URL.localDb.path)
        try queue.backup(to: DatabaseQueue(path: URL.tempDb.path))
        defer { try? FileManager.default.removeItem(at: .tempDb) }
        let dbData = try Data(contentsOf: .tempDb)
        let uploadUrl = try await self.api.createDatabaseUpload(installId)
        var request = URLRequest(url: uploadUrl, cachePolicy: .reloadIgnoringCacheData)
        request.httpMethod = "PUT"
        request.addValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        let (_, response) = try await URLSession.shared.upload(for: request, from: dbData)
        guard let httpResponse = response as? HTTPURLResponse,
              (200 ... 299).contains(httpResponse.statusCode) else {
          log(.error("b4c8d7e2"), "upload db fail: unexpected response")
          await send(.delegate(.alert("DB upload failed, unexpected response")))
          return
        }
        log(.info("a5f6b9c3"), "upload db success")
        await send(.delegate(.alert("DB upload success: \(installId)")))
      }
    }

    if input.starts(with: "am: download db 660b2f93 ") {
      let urlString = String(input.dropFirst("am: download db 660b2f93 ".count))
      guard let url = URL(string: urlString) else {
        log(.error("d8e9f1a2"), "download db fail: invalid url")
        return .send(.delegate(.alert("DB download failed, invalid URL")))
      }

      return .run { send in
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200 ... 299).contains(httpResponse.statusCode) else {
          log(.error("e9f1a2b3"), "download db fail: bad response")
          await send(.delegate(.alert("DB download failed, bad response")))
          return
        }
        try data.write(to: .tempDb)
        log(.info("f1a2b3c4"), "download db success")
        await send(.delegate(.alert("DB download success, restart app")))
      }
    }

    if input == "am: c731abbfe9d" {
      return .run { send in
        try CurrentSubscription.set(status: .complimentary, expiringAt: .distantFuture)
        log(.info("111b15d5"), "set subscription to complimentary")
        await send(.delegate(.alert("Subscription set to complimentary :)")))
      }
    }

    if input.starts(with: "am: log db ") {
      let table = String(input.dropFirst("am: log db ".count))
      switch table {
      case "shows":
        let shows = self.db.tryRead { try Show.all.fetchAll($0) }
        for show in shows {
          os_log(
            "[G•] Show %{public}d: %{public}@",
            show.id.rawValue,
            String(describing: show),
          )
        }
      case "episodes":
        let episodes = self.db.tryRead { try Episode.all.fetchAll($0) }
        for episode in episodes {
          os_log(
            "[G•] Episode %{public}d: %{public}@",
            episode.id.rawValue,
            String(describing: episode),
          )
        }
      case "pinAttempts":
        let attempts = self.db.tryRead { try PinAttempt.all.fetchAll($0) }
        for attempt in attempts {
          os_log(
            "[G•] PinAttempt %{public}d: %{public}@",
            attempt.id.rawValue,
            String(describing: attempt),
          )
        }
      case "records":
        let records = self.db.tryRead { try Record.all.fetchAll($0) }
        for record in records {
          os_log(
            "[G•] Record %{public}d: %{public}@",
            record.id.rawValue,
            String(describing: record),
          )
        }
      case "events":
        let events = self.db.tryRead { try Event.all.fetchAll($0) }
        for event in events {
          os_log(
            "[G•] Event %{public}d: %{public}@",
            event.id.rawValue,
            String(describing: event),
          )
        }
      default:
        break
      }
      return .send(.setScreen(.choosingMethod))
    }

    return nil
  }
}
