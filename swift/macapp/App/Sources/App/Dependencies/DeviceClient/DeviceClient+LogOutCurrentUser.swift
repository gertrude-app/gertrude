import Foundation

enum LogOutCurrentUserError: Error, Equatable {
  case launchFailed(String)
  case unknownFailure(stderr: String)
}

@Sendable func doLogOutCurrentUser() async throws {
  let proc = Process()
  let stderr = Pipe()
  proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
  proc.arguments = ["-e", "tell application \"loginwindow\" to «event aevtrlgo»"]
  proc.standardOutput = FileHandle.nullDevice
  proc.standardError = stderr

  try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
    proc.terminationHandler = { _ in cont.resume(returning: ()) }
    do {
      try proc.run()
    } catch {
      cont.resume(throwing: LogOutCurrentUserError.launchFailed("\(error)"))
    }
  }

  if proc.terminationStatus == 0 {
    return
  }

  let errData = stderr.fileHandleForReading.readDataToEndOfFile()
  let errString = String(data: errData, encoding: .utf8) ?? ""
  throw LogOutCurrentUserError.unknownFailure(stderr: errString)
}
