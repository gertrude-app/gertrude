#if canImport(ReplayKit)
  import Accelerate
  import CoreImage
  import Dependencies
  import ReplayKit

  public final class FramePipeline {
    private let ciContext = CIContext()
    private var previousThumbnail: CGImage?
    private let halfSize = CGAffineTransform(scaleX: 0.5, y: 0.5)

    @Dependency(\.osLog) private var logger

    public init() {}

    public func frame(from buffer: CMSampleBuffer) -> Frame? {
      guard let currentScreen = self.ciImage(from: buffer),
            let thumbnail = self.thumbnail(of: currentScreen) else {
        self.logger.log("failed to create cgImage from sample buffer")
        return nil
      }
      let width = Int(currentScreen.extent.width)
      let height = Int(currentScreen.extent.height)

      if thumbnail.isNearlyIdenticalTo(self.previousThumbnail) {
        self.ciContext.clearCaches()
        return Frame(jpeg: Data(), width: width, height: height, unchanged: true)
      }

      self.previousThumbnail = thumbnail
      guard let jpeg = self.jpegData(from: currentScreen) else {
        self.ciContext.clearCaches()
        return nil
      }
      self.ciContext.clearCaches()
      return Frame(jpeg: jpeg, width: width, height: height, unchanged: false)
    }

    private func ciImage(from sampleBuffer: CMSampleBuffer) -> CIImage? {
      guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
        self.logger.log("CMSampleBufferGetImageBuffer failed")
        return nil
      }
      return CIImage(cvImageBuffer: imageBuffer)
        .transformed(by: self.halfSize)
        .oriented(self.upright(self.orientation(of: sampleBuffer)))
    }

    private func upright(
      _ orientation: CGImagePropertyOrientation?,
    ) -> CGImagePropertyOrientation {
      switch orientation {
      case .left: .right
      case .right: .left
      case .rightMirrored: .leftMirrored
      case .leftMirrored: .rightMirrored
      default: orientation ?? .up
      }
    }

    private func orientation(of buffer: CMSampleBuffer) -> CGImagePropertyOrientation? {
      (CMGetAttachment(
        buffer,
        key: RPVideoSampleOrientationKey as CFString,
        attachmentModeOut: nil,
      ) as? NSNumber)
        .flatMap { CGImagePropertyOrientation(rawValue: $0.uint32Value) }
    }

    // NB: full-size comparison makes the extension run out of memory
    private func thumbnail(of ciImage: CIImage) -> CGImage? {
      let scaledImage = ciImage.transformed(by: self.halfSize)
      return self.ciContext.createCGImage(scaledImage, from: scaledImage.extent)
    }

    private func jpegData(from ciImage: CIImage) -> Data? {
      guard let colorSpace = ciImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB) else {
        self.logger.log("no suitable color space for jpeg screenshot")
        return nil
      }
      return self.ciContext.jpegRepresentation(
        of: ciImage,
        colorSpace: colorSpace,
        options: [
          kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.7,
        ],
      )
    }
  }

  extension CGImage {
    var bytes: Data? {
      guard let provider = dataProvider, let bytes = provider.data as Data? else {
        return nil
      }
      return bytes
    }

    func isNearlyIdenticalTo(_ other: CGImage?) -> Bool {
      guard let other,
            self.width == other.width,
            self.height == other.height,
            let data = self.bytes,
            let otherData = other.bytes,
            data.count == otherData.count else {
        return false
      }
      return self.meanAbsoluteDifference(data, otherData) < 0.001
    }

    private func meanAbsoluteDifference(_ data1: Data, _ data2: Data) -> Float {
      let length = data1.count
      var floatArray1 = [Float](repeating: 0.0, count: length)
      var floatArray2 = [Float](repeating: 0.0, count: length)
      vDSP.convertElements(of: [UInt8](data1), to: &floatArray1)
      vDSP.convertElements(of: [UInt8](data2), to: &floatArray2)
      let mean = vDSP.mean(vDSP.absolute(vDSP.subtract(floatArray1, floatArray2)))
      return mean / 255.0
    }
  }
#endif
