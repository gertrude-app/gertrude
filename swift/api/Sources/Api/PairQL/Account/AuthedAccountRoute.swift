import Foundation
import PairQL
import Vapor

enum AuthedAccountRoute: PairRoute {
  case getPeople
  case getDevices
  case createPerson(CreatePerson.Input)
  case updatePersonBasicDetails(UpdatePersonBasicDetails.Input)
  case deletePerson(DeletePerson.Input)
  case getAccountKeychains
  case getAccountKeychain(GetAccountKeychain.Input)
  case setAccountKeychainAssignment(SetAccountKeychainAssignment.Input)
  case getPersonMacSettings(GetPersonMacSettings.Input)
  case getPersonInstalledMacApps(GetPersonInstalledMacApps.Input)
  case updatePersonMacMonitoringSettings(UpdatePersonMacMonitoringSettings.Input)
  case updatePersonMacInternetFiltering(UpdatePersonMacInternetFiltering.Input)
  case updatePersonMacApps(UpdatePersonMacApps.Input)
  case getIosDeviceSettings(GetIosDeviceSettings.Input)
  case updateIosDeviceBlockedGroups(UpdateIosDeviceBlockedGroups.Input)
  case updateIosDeviceProfileSettings(UpdateIosDeviceProfileSettings.Input)
  case requestPodcastsPinReset(RequestPodcastsPinReset.Input)
  case requestAccountPublicKeychain(RequestAccountPublicKeychain.Input)
  case getSuspensionRequests
  case decideSuspensionRequest(DecideSuspensionRequest.Input)
  case getSecurityEvents
  case getActivitySummaries(GetActivitySummaries.Input)
  case getDayActivity(GetDayActivity.Input)
  case getPersonActivitySummaries(GetPersonActivitySummaries.Input)
  case getPersonDayActivity(GetPersonDayActivity.Input)
  case toggleActivityFlag(ToggleActivityFlag.Input)
  case deleteActivity(DeleteActivity.Input)

  nonisolated(unsafe) static let router = OneOf {
    Route(.case(Self.getPeople)) {
      Operation(GetPeople.self)
    }
    Route(.case(Self.getDevices)) {
      Operation(GetDevices.self)
    }
    Route(.case(Self.createPerson)) {
      Operation(CreatePerson.self)
      Body(.accountInput(CreatePerson.self))
    }
    Route(.case(Self.updatePersonBasicDetails)) {
      Operation(UpdatePersonBasicDetails.self)
      Body(.accountInput(UpdatePersonBasicDetails.self))
    }
    Route(.case(Self.deletePerson)) {
      Operation(DeletePerson.self)
      Body(.accountInput(DeletePerson.self))
    }
    Route(.case(Self.getAccountKeychains)) {
      Operation(GetAccountKeychains.self)
    }
    Route(.case(Self.getAccountKeychain)) {
      Operation(GetAccountKeychain.self)
      Body(.accountInput(GetAccountKeychain.self))
    }
    Route(.case(Self.setAccountKeychainAssignment)) {
      Operation(SetAccountKeychainAssignment.self)
      Body(.accountInput(SetAccountKeychainAssignment.self))
    }
    Route(.case(Self.getPersonMacSettings)) {
      Operation(GetPersonMacSettings.self)
      Body(.accountInput(GetPersonMacSettings.self))
    }
    Route(.case(Self.getPersonInstalledMacApps)) {
      Operation(GetPersonInstalledMacApps.self)
      Body(.accountInput(GetPersonInstalledMacApps.self))
    }
    Route(.case(Self.updatePersonMacMonitoringSettings)) {
      Operation(UpdatePersonMacMonitoringSettings.self)
      Body(.accountInput(UpdatePersonMacMonitoringSettings.self))
    }
    Route(.case(Self.updatePersonMacInternetFiltering)) {
      Operation(UpdatePersonMacInternetFiltering.self)
      Body(.accountInput(UpdatePersonMacInternetFiltering.self))
    }
    Route(.case(Self.updatePersonMacApps)) {
      Operation(UpdatePersonMacApps.self)
      Body(.accountInput(UpdatePersonMacApps.self))
    }
    Route(.case(Self.getIosDeviceSettings)) {
      Operation(GetIosDeviceSettings.self)
      Body(.accountInput(GetIosDeviceSettings.self))
    }
    Route(.case(Self.updateIosDeviceBlockedGroups)) {
      Operation(UpdateIosDeviceBlockedGroups.self)
      Body(.accountInput(UpdateIosDeviceBlockedGroups.self))
    }
    Route(.case(Self.updateIosDeviceProfileSettings)) {
      Operation(UpdateIosDeviceProfileSettings.self)
      Body(.accountInput(UpdateIosDeviceProfileSettings.self))
    }
    Route(.case(Self.requestPodcastsPinReset)) {
      Operation(RequestPodcastsPinReset.self)
      Body(.accountInput(RequestPodcastsPinReset.self))
    }
    Route(.case(Self.requestAccountPublicKeychain)) {
      Operation(RequestAccountPublicKeychain.self)
      Body(.accountInput(RequestAccountPublicKeychain.self))
    }
    Route(.case(Self.getSuspensionRequests)) {
      Operation(GetSuspensionRequests.self)
    }
    Route(.case(Self.decideSuspensionRequest)) {
      Operation(DecideSuspensionRequest.self)
      Body(.accountInput(DecideSuspensionRequest.self))
    }
    Route(.case(Self.getSecurityEvents)) {
      Operation(GetSecurityEvents.self)
    }
    Route(.case(Self.getActivitySummaries)) {
      Operation(GetActivitySummaries.self)
      Body(.accountInput(GetActivitySummaries.self))
    }
    Route(.case(Self.getDayActivity)) {
      Operation(GetDayActivity.self)
      Body(.accountInput(GetDayActivity.self))
    }
    Route(.case(Self.getPersonActivitySummaries)) {
      Operation(GetPersonActivitySummaries.self)
      Body(.accountInput(GetPersonActivitySummaries.self))
    }
    Route(.case(Self.getPersonDayActivity)) {
      Operation(GetPersonDayActivity.self)
      Body(.accountInput(GetPersonDayActivity.self))
    }
    Route(.case(Self.toggleActivityFlag)) {
      Operation(ToggleActivityFlag.self)
      Body(.accountInput(ToggleActivityFlag.self))
    }
    Route(.case(Self.deleteActivity)) {
      Operation(DeleteActivity.self)
      Body(.accountInput(DeleteActivity.self))
    }
  }
}

extension AuthedAccountRoute: RouteResponder {
  static func respond(to route: Self, in context: AccountOwnerContext) async throws -> Response {
    switch route {
    case .getPeople:
      let output = try await GetPeople.resolve(in: context)
      return try await self.respond(with: output)
    case .getDevices:
      let output = try await GetDevices.resolve(in: context)
      return try await self.respond(with: output)
    case .createPerson(let input):
      let output = try await CreatePerson.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .updatePersonBasicDetails(let input):
      let output = try await UpdatePersonBasicDetails.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .deletePerson(let input):
      let output = try await DeletePerson.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getAccountKeychains:
      let output = try await GetAccountKeychains.resolve(in: context)
      return try await self.respond(with: output)
    case .getAccountKeychain(let input):
      let output = try await GetAccountKeychain.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .setAccountKeychainAssignment(let input):
      let output = try await SetAccountKeychainAssignment.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getPersonMacSettings(let input):
      let output = try await GetPersonMacSettings.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getPersonInstalledMacApps(let input):
      let output = try await GetPersonInstalledMacApps.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .updatePersonMacMonitoringSettings(let input):
      let output = try await UpdatePersonMacMonitoringSettings.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .updatePersonMacInternetFiltering(let input):
      let output = try await UpdatePersonMacInternetFiltering.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .updatePersonMacApps(let input):
      let output = try await UpdatePersonMacApps.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getIosDeviceSettings(let input):
      let output = try await GetIosDeviceSettings.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .updateIosDeviceBlockedGroups(let input):
      let output = try await UpdateIosDeviceBlockedGroups.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .updateIosDeviceProfileSettings(let input):
      let output = try await UpdateIosDeviceProfileSettings.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .requestPodcastsPinReset(let input):
      let output = try await RequestPodcastsPinReset.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .requestAccountPublicKeychain(let input):
      let output = try await RequestAccountPublicKeychain.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getSuspensionRequests:
      let output = try await GetSuspensionRequests.resolve(in: context)
      return try await self.respond(with: output)
    case .decideSuspensionRequest(let input):
      let output = try await DecideSuspensionRequest.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getSecurityEvents:
      let output = try await GetSecurityEvents.resolve(in: context)
      return try await self.respond(with: output)
    case .getActivitySummaries(let input):
      let output = try await GetActivitySummaries.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getDayActivity(let input):
      let output = try await GetDayActivity.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getPersonActivitySummaries(let input):
      let output = try await GetPersonActivitySummaries.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .getPersonDayActivity(let input):
      let output = try await GetPersonDayActivity.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .toggleActivityFlag(let input):
      let output = try await ToggleActivityFlag.resolve(with: input, in: context)
      return try await self.respond(with: output)
    case .deleteActivity(let input):
      let output = try await DeleteActivity.resolve(with: input, in: context)
      return try await self.respond(with: output)
    }
  }
}
