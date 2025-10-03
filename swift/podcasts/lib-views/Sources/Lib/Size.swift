import Foundation

public func formatFileSize(_ bytes: Int) -> String {
  let kb = 1024
  let mb = kb * 1024
  let gb = mb * 1024

  if bytes >= gb {
    let value = Double(bytes) / Double(gb)
    return String(format: "%.1f GB", value)
  } else if bytes >= mb {
    let value = Double(bytes) / Double(mb)
    return String(format: "%.1f MB", value)
  } else if bytes >= kb {
    let value = Double(bytes) / Double(kb)
    return String(format: "%.1f KB", value)
  } else {
    return "\(bytes) bytes"
  }
}
