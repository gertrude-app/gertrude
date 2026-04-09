import Foundation

enum CreateStandardUserError: Error, Equatable {
  case alreadyExists
  case cancelledByAdminAuth
  case parentMissingSecureToken
  case unknownFailure(stderr: String)
}

func classifyCreateStandardUserFailure(stderr: String) -> CreateStandardUserError {
  if stderr.contains("errAuthorizationCanceled") {
    return .cancelledByAdminAuth
  }
  return .unknownFailure(stderr: stderr)
}

@Sendable func getParentHasSecureToken() async -> Bool {
  await Task {
    let proc = Process()
    let stderr = Pipe()
    proc.executableURL = URL(fileURLWithPath: "/usr/sbin/sysadminctl")
    proc.arguments = ["-secureTokenStatus", NSUserName()]
    proc.standardOutput = FileHandle.nullDevice
    proc.standardError = stderr
    do {
      try proc.run()
      proc.waitUntilExit()
    } catch {
      return false
    }
    let data = stderr.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""
    return output.contains("ENABLED")
  }.value
}

@Sendable func macOSUserExists(_ shortName: String) async -> Bool {
  await Task {
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: "/usr/bin/id")
    proc.arguments = [shortName]
    proc.standardOutput = FileHandle.nullDevice
    proc.standardError = FileHandle.nullDevice
    do {
      try proc.run()
      proc.waitUntilExit()
      return proc.terminationStatus == 0
    } catch {
      return false
    }
  }.value
}

@Sendable func createStandardUser(
  shortName: String,
  fullName: String,
  password: String,
) async throws {
  if await !getParentHasSecureToken() {
    throw CreateStandardUserError.parentMissingSecureToken
  }

  if await macOSUserExists(shortName) {
    throw CreateStandardUserError.alreadyExists
  }

  let proc = Process()
  let stdin = Pipe()
  let stderr = Pipe()
  proc.executableURL = URL(fileURLWithPath: "/usr/sbin/sysadminctl")
  proc.arguments = [
    "-addUser", shortName,
    "-fullName", fullName,
    "-password", "-",
    "interactive",
  ]
  proc.standardInput = stdin
  proc.standardOutput = FileHandle.nullDevice
  proc.standardError = stderr

  try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
    proc.terminationHandler = { _ in cont.resume(returning: ()) }
    do {
      try proc.run()
      stdin.fileHandleForWriting.write(Data((password + "\n").utf8))
      try? stdin.fileHandleForWriting.close()
    } catch {
      cont.resume(throwing: CreateStandardUserError.unknownFailure(stderr: "\(error)"))
    }
  }

  let errData = stderr.fileHandleForReading.readDataToEndOfFile()
  let errString = String(data: errData, encoding: .utf8) ?? ""

  if await macOSUserExists(shortName) {
    return
  }

  throw classifyCreateStandardUserFailure(stderr: errString)
}
