import LibRecorder
import ReplayKit

class SampleHandler: RPBroadcastSampleHandler, FinishableBroadcast {
  lazy var proxy = SampleHandlerProxy(finisher: self)
  let pipeline = FramePipeline()

  override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
    self.proxy.broadcastStarted()
  }

  override func broadcastPaused() {
    self.proxy.broadcastPaused()
  }

  override func broadcastResumed() {
    self.proxy.broadcastResumed()
  }

  override func broadcastFinished() {
    self.proxy.broadcastFinished()
  }

  override func processSampleBuffer(
    _ sampleBuffer: CMSampleBuffer,
    with sampleBufferType: RPSampleBufferType,
  ) {
    guard sampleBufferType == .video, self.proxy.shouldProcessBuffer() else { return }
    if let frame = self.pipeline.frame(from: sampleBuffer) {
      self.proxy.processFrame(frame)
    }
  }

  func finishWithError(_ error: any Error) {
    self.finishBroadcastWithError(error)
  }
}
