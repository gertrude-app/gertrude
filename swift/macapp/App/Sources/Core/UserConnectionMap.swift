import Foundation

public struct UserConnectionMap<C: Sendable>: Sendable {
  public struct Entry: Sendable {
    public let connection: C
    public let seq: Int
  }

  public private(set) var entries: [uid_t: Entry] = [:]
  private var nextSeq = 0

  public init() {}

  public var mostRecent: C? {
    self.entries.values.max { $0.seq < $1.seq }?.connection
  }

  public var mostRecentUid: uid_t? {
    self.entries.max { $0.value.seq < $1.value.seq }?.key
  }

  public var connectedUids: Set<uid_t> {
    Set(self.entries.keys)
  }

  public func connection(for uid: uid_t) -> C? {
    self.entries[uid]?.connection
  }

  public func has(_ uid: uid_t) -> Bool {
    self.entries[uid] != nil
  }

  public mutating func connect(_ connection: C, for uid: uid_t) {
    self.entries[uid] = Entry(connection: connection, seq: self.nextSeq)
    self.nextSeq += 1
  }

  public mutating func disconnect(_ uid: uid_t) {
    self.entries[uid] = nil
  }

  public mutating func disconnect(_ uid: uid_t, where condition: (C) -> Bool) {
    guard let entry = self.entries[uid], condition(entry.connection) else { return }
    self.entries[uid] = nil
  }

  public mutating func clear() {
    self = .init()
  }
}

public extension UserConnectionMap where C == Void {
  mutating func connect(_ uid: uid_t) {
    self.connect((), for: uid)
  }
}
