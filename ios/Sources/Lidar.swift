import ARKit
import Vision

// The phone's LiDAR sensor, read through ARKit. About ten times a second it reports how far away whatever is straight
// ahead is, and, when a hand is in the camera's view, where the index fingertip is and how far away the hand is.
// While it runs it holds the rear camera, so the web page cannot open that camera at the same time.
final class Lidar: NSObject, ARSessionDelegate {
  struct Reading {
    var centre: Float?                     // metres to whatever is in the middle of the camera's view
    var hand: (u: Double, v: Double, d: Float?)?  // index fingertip across and down the camera picture (0..1), and metres to the hand
  }

  static var supported: Bool { ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) }

  var onReading: ((Reading) -> Void)?      // called on the main thread
  private(set) var running = false
  private let session = ARSession()
  private let queue = DispatchQueue(label: "fruitvr.lidar")
  private let handRequest = VNDetectHumanHandPoseRequest()
  private var lastSent: TimeInterval = 0

  override init() {
    super.init()
    handRequest.maximumHandCount = 1
    session.delegate = self
    session.delegateQueue = queue
  }

  func start() {
    guard Lidar.supported, !running else { return }
    let cfg = ARWorldTrackingConfiguration()
    cfg.frameSemantics = .sceneDepth
    session.run(cfg, options: [.resetTracking, .removeExistingAnchors])
    running = true
  }

  func stop() {
    guard running else { return }
    session.pause()
    running = false
  }

  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    guard frame.timestamp - lastSent >= 0.1, let depth = frame.sceneDepth?.depthMap else { return }
    lastSent = frame.timestamp
    var reading = Reading(centre: Lidar.depth(depth, u: 0.5, v: 0.5, radius: 4, quantile: 0.5), hand: nil)

    // the hand: Apple's hand finder on the camera picture, then the depth at the knuckles and wrist
    let handler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, orientation: .up, options: [:])
    if (try? handler.perform([handRequest])) != nil, let obs = handRequest.results?.first,
       let tip = try? obs.recognizedPoint(.indexTip), tip.confidence > 0.3 {
      var ds: [Float] = []
      for joint in [VNHumanHandPoseObservation.JointName.indexMCP, .middleMCP, .wrist, .indexTip] {
        if let p = try? obs.recognizedPoint(joint), p.confidence > 0.3,
           let d = Lidar.depth(depth, u: Double(p.location.x), v: 1 - Double(p.location.y), radius: 2, quantile: 0.25) {
          ds.append(d)
        }
      }
      ds.sort()
      // Vision counts up from the bottom of the picture; the page counts down from the top
      reading.hand = (Double(tip.location.x), 1 - Double(tip.location.y), ds.isEmpty ? nil : ds[ds.count / 2])
    }
    DispatchQueue.main.async { [weak self] in self?.onReading?(reading) }
  }

  // The depth, in metres, around a point of the depth picture (0..1 across and down): the given quantile of the valid
  // values in a small square, so one stray value doesn't decide it. A low quantile favours the nearer surface, which is
  // what is wanted at the edge of a hand.
  private static func depth(_ map: CVPixelBuffer, u: Double, v: Double, radius: Int, quantile: Double) -> Float? {
    guard CVPixelBufferGetPixelFormatType(map) == kCVPixelFormatType_DepthFloat32 else { return nil }
    CVPixelBufferLockBaseAddress(map, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(map, .readOnly) }
    guard let base = CVPixelBufferGetBaseAddress(map) else { return nil }
    let w = CVPixelBufferGetWidth(map), h = CVPixelBufferGetHeight(map), rowBytes = CVPixelBufferGetBytesPerRow(map)
    guard w > 0, h > 0, u.isFinite, v.isFinite else { return nil }
    let cx = min(w - 1, max(0, Int(u * Double(w)))), cy = min(h - 1, max(0, Int(v * Double(h))))
    var vals: [Float] = []
    for y in max(0, cy - radius)...min(h - 1, cy + radius) {
      let row = (base + y * rowBytes).assumingMemoryBound(to: Float32.self)
      for x in max(0, cx - radius)...min(w - 1, cx + radius) {
        let d = row[x]
        if d.isFinite && d > 0 { vals.append(d) }
      }
    }
    guard !vals.isEmpty else { return nil }
    vals.sort()
    return vals[min(vals.count - 1, Int(Double(vals.count) * quantile))]
  }
}
