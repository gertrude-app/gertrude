import DuetSQL
import Gertie

@DuetModel(schema: "child", table: "unrestricted_mac_apps")
struct UnrestrictedMacApp: Codable, Sendable {
  var id: Id
  var scope: AppScope.Single
  var childId: Child.Id
  var schedule: RuleSchedule?
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    scope: AppScope.Single,
    childId: Child.Id,
    schedule: RuleSchedule? = nil,
  ) {
    self.id = id
    self.scope = scope
    self.childId = childId
    self.schedule = schedule
  }
}

// extensions

extension UnrestrictedMacApp {
  var dto: DTO {
    DTO(id: self.id, scope: self.scope, schedule: self.schedule)
  }

  struct DTO: Codable, Equatable, Sendable {
    var id: Id
    var scope: AppScope.Single
    var schedule: RuleSchedule?

    init(
      id: Id = .init(),
      scope: AppScope.Single,
      schedule: RuleSchedule? = nil,
    ) {
      self.id = id
      self.scope = scope
      self.schedule = schedule
    }
  }
}

extension UnrestrictedMacApp {
  init(dto: DTO, childId: Child.Id) {
    self.init(id: dto.id, scope: dto.scope, childId: childId, schedule: dto.schedule)
  }
}
