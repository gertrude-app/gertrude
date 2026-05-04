import Foundation

struct RouteTelemetry: Codable, Sendable {
  enum Result: String, Codable, Sendable {
    case ok
    case pqlError = "pql_error"
    case convertibleError = "convertible_error"
    case unexpectedError = "unexpected_error"
    case notFound = "not_found"
  }

  var id: Id
  var kind: String
  var requestId: String
  var domain: String
  var operation: String
  var durationMs: Int
  var result: Result
  var errorId: String?
  var errorType: String?
  var errorMessage: String?
  var parentId: Parent.Id?
  var ipAddress: String?
  var userAgent: String?
  var requestBytes: Int?
  var responseBytes: Int?
  var createdAt = Date()

  init(
    id: Id = .init(),
    kind: String,
    requestId: String,
    domain: String,
    operation: String,
    durationMs: Int,
    result: Result,
    errorId: String? = nil,
    errorType: String? = nil,
    errorMessage: String? = nil,
    parentId: Parent.Id? = nil,
    ipAddress: String? = nil,
    userAgent: String? = nil,
    requestBytes: Int? = nil,
    responseBytes: Int? = nil,
  ) {
    self.id = id
    self.kind = kind
    self.requestId = requestId
    self.domain = domain
    self.operation = operation
    self.durationMs = durationMs
    self.result = result
    self.errorId = errorId
    self.errorType = errorType
    self.errorMessage = errorMessage
    self.parentId = parentId
    self.ipAddress = ipAddress
    self.userAgent = userAgent
    self.requestBytes = requestBytes
    self.responseBytes = responseBytes
  }
}
