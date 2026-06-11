import Foundation

func formatShortDuration(_ seconds: Int, lang: Lang) -> String {
  let hours = seconds / 3600
  let minutes = (seconds % 3600) / 60
  let minuteUnit = lang == .spanish ? "min" : "m"

  if hours > 0 {
    if minutes > 0 {
      return "\(hours)h \(minutes)\(minuteUnit)"
    } else {
      return "\(hours)h"
    }
  } else {
    return "\(minutes)\(minuteUnit)"
  }
}

func formatRelativeDate(_ date: Date, lang: Lang) -> String {
  let now = Date()
  let timeInterval = now.timeIntervalSince(date)

  if timeInterval < 60 {
    return lang == .spanish ? "justo ahora" : "just now"
  }

  if timeInterval < 3600 {
    let minutes = Int(timeInterval / 60)
    return lang == .spanish ? "\(minutes) min" : "\(minutes)m ago"
  }

  if timeInterval < 86400 {
    let hours = Int(timeInterval / 3600)
    return lang == .spanish ? "hace \(hours)h" : "\(hours)h ago"
  }

  if timeInterval < 604_800 {
    let days = Int(timeInterval / 86400)
    return lang == .spanish ? "hace \(days)d" : "\(days)d ago"
  }

  let formatter = DateFormatter()
  formatter.dateFormat = DateFormatter.dateFormat(
    fromTemplate: "MMMd",
    options: 0,
    locale: .current,
  )
  formatter.locale = Locale.current
  return formatter.string(from: date)
}

func formatLegacyAccessDate(_ date: Date, includeYear: Bool) -> String {
  let formatter = DateFormatter()
  formatter.dateFormat = DateFormatter.dateFormat(
    fromTemplate: includeYear ? "MMMdyyyy" : "MMMd",
    options: 0,
    locale: .current,
  )
  formatter.locale = Locale.current
  return formatter.string(from: date)
}

public func formatPlayerTime(_ seconds: Int) -> String {
  let hours = seconds / 3600
  let minutes = (seconds % 3600) / 60
  let secs = seconds % 60

  if hours > 0 {
    return String(format: "%d:%02d:%02d", hours, minutes, secs)
  } else {
    return String(format: "%d:%02d", minutes, secs)
  }
}

public func formatRemainingPlayerTime(
  progress: Double,
  durationSeconds: Int?,
  withMinus: Bool = true,
) -> String {
  guard let durationSeconds, durationSeconds > 0 else { return "0:00" }
  let currentSeconds = max(0, Int(progress))
  let remainingSeconds = max(0, durationSeconds - currentSeconds)
  return (withMinus ? "-" : "") + formatPlayerTime(remainingSeconds)
}

extension TimeInterval {
  static func days(_ days: Int) -> Self {
    Self(days * 60 * 60 * 24)
  }

  static func hours(_ hours: Int) -> Self {
    Self(hours * 60 * 60)
  }

  static func minutes(_ minutes: Int) -> Self {
    Self(minutes * 60)
  }

  static func seconds(_ seconds: Int) -> Self {
    Self(seconds)
  }
}
