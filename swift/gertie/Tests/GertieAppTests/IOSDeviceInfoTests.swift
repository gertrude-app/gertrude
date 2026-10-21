import Foundation
import Testing

#if canImport(Darwin)
  import Darwin
#elseif canImport(Glibc)
  import Glibc
#endif

@testable import GertieApp

struct IOSDeviceInfoTests {
  @Test func `model identifier is not empty`() {
    #expect(!IOSDeviceInfo.modelIdentifier().isEmpty)
  }

  @Test func `model identifier matches the target device`() throws {
    #if targetEnvironment(simulator)
      let expected = try #require(ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"])
    #else
      var systemInfo = utsname()
      uname(&systemInfo)
      let capacity = MemoryLayout.size(ofValue: systemInfo.machine)
      let expected = withUnsafePointer(to: &systemInfo.machine) { pointer in
        pointer.withMemoryRebound(to: CChar.self, capacity: capacity) {
          String(cString: $0)
        }
      }
    #endif
    #expect(IOSDeviceInfo.modelIdentifier() == expected)
  }
}
