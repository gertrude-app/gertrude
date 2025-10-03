import Foundation
import Testing

@testable import LibViews

@Test
func testFormatFileSizeBytes() {
  #expect(formatFileSize(0) == "0 bytes")
  #expect(formatFileSize(500) == "500 bytes")
  #expect(formatFileSize(1023) == "1023 bytes")
}

@Test
func testFormatFileSizeKilobytes() {
  #expect(formatFileSize(1024) == "1.0 KB")
  #expect(formatFileSize(1536) == "1.5 KB")
  #expect(formatFileSize(10240) == "10.0 KB")
  #expect(formatFileSize(102_400) == "100.0 KB")
  #expect(formatFileSize(1_048_575) == "1024.0 KB")
}

@Test
func testFormatFileSizeMegabytes() {
  #expect(formatFileSize(1_048_576) == "1.0 MB")
  #expect(formatFileSize(5_242_880) == "5.0 MB")
  #expect(formatFileSize(52_428_800) == "50.0 MB")
  #expect(formatFileSize(1_073_741_823) == "1024.0 MB")
}

@Test
func testFormatFileSizeGigabytes() {
  #expect(formatFileSize(1_073_741_824) == "1.0 GB")
  #expect(formatFileSize(2_147_483_648) == "2.0 GB")
  #expect(formatFileSize(5_368_709_120) == "5.0 GB")
}

@Test
func testFormatFileSizeRounding() {
  #expect(formatFileSize(1536) == "1.5 KB")
  #expect(formatFileSize(1_572_864) == "1.5 MB")
  #expect(formatFileSize(1_610_612_736) == "1.5 GB")
}
