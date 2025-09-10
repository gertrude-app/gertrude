import Foundation

func formatDuration(_ seconds: Int) -> String {
  let hours = seconds / 3600
  let minutes = (seconds % 3600) / 60

  if hours > 0 {
    if minutes > 0 {
      return "\(hours)h \(minutes)m"
    } else {
      return "\(hours)h"
    }
  } else {
    return "\(minutes)m"
  }
}

func formatRelativeDate(_ date: Date) -> String {
  let now = Date()
  let timeInterval = now.timeIntervalSince(date)

  if timeInterval < 60 {
    return "JUST NOW"
  }

  if timeInterval < 3600 {
    let minutes = Int(timeInterval / 60)
    return "\(minutes)M AGO"
  }

  if timeInterval < 86400 {
    let hours = Int(timeInterval / 3600)
    return "\(hours)H AGO"
  }

  if timeInterval < 604_800 {
    let days = Int(timeInterval / 86400)
    return "\(days)D AGO"
  }

  let formatter = DateFormatter()
  formatter.dateFormat = "MMM d"
  formatter.locale = Locale(identifier: "en_US_POSIX")
  return formatter.string(from: date).uppercased()
}
