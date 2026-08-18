import DuetSQL
import Foundation

@DuetModel(schema: "system", table: "site_form_submissions")
struct SiteFormSubmission: Codable, Sendable {
  var id: Id
  var form: Form
  var app: App?
  var name: String
  var email: String
  var subject: String?
  var message: String
  var parentId: Parent.Id?
  var createdAt = Date()

  enum Form: String, Codable, Sendable {
    case contact
    case lockdownGuide
    case fiveThings
  }

  enum App: String, Codable, Sendable {
    case mac
    case blocker
    case podcasts
    case music
    case unsure
  }

  init(
    id: Id = .init(),
    form: Form,
    app: App? = nil,
    name: String,
    email: String,
    subject: String? = nil,
    message: String,
    parentId: Parent.Id? = nil,
  ) {
    self.id = id
    self.form = form
    self.app = app
    self.name = name
    self.email = email
    self.subject = subject
    self.message = message
    self.parentId = parentId
  }
}
