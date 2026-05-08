import Duet
import PostgresKit

struct TransactionClient: Client {
  private let client: any Client
  private let lock = TransactionLock()

  init(client: any Client) {
    self.client = client
  }

  func execute(raw: SQLQueryString) async throws -> [SQLRow] {
    try await self.withLock {
      try await self.client.execute(raw: raw)
    }
  }

  func execute(statement: SQL.Statement) async throws -> [SQLRow] {
    try await self.withLock {
      try await self.client.execute(statement: statement)
    }
  }

  func execute<M: Model>(statement: SQL.Statement, returning: M.Type) async throws -> [M] {
    try await self.withLock {
      try await self.client.execute(statement: statement, returning: returning)
    }
  }

  @discardableResult
  func transaction<R>(
    _ operation: @escaping @Sendable (any Client) async throws -> R,
  ) async throws -> R {
    try await operation(self)
  }

  private func withLock<R>(_ operation: () async throws -> R) async throws -> R {
    try await self.lock.lock()
    do {
      try Task.checkCancellation()
      let result = try await operation()
      await self.lock.unlock()
      return result
    } catch {
      await self.lock.unlock()
      throw error
    }
  }
}

private actor TransactionLock {
  private struct Waiter {
    let id: Int
    let continuation: CheckedContinuation<Void, any Error>
  }

  private var isLocked = false
  private var nextWaiterId = 0
  private var waiters: [Waiter] = []

  func lock() async throws {
    if Task.isCancelled {
      throw CancellationError()
    }
    guard self.isLocked else {
      self.isLocked = true
      return
    }

    let waiterId = self.nextWaiterId
    self.nextWaiterId += 1
    try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        self.waiters.append(Waiter(id: waiterId, continuation: continuation))
      }
    } onCancel: {
      Task {
        await self.cancelWaiter(id: waiterId)
      }
    }
  }

  private func cancelWaiter(id: Int) {
    if let index = self.waiters.firstIndex(where: { $0.id == id }) {
      self.waiters.remove(at: index).continuation.resume(throwing: CancellationError())
    }
  }

  func unlock() {
    if self.waiters.isEmpty {
      self.isLocked = false
    } else {
      self.waiters.removeFirst().continuation.resume()
    }
  }
}
