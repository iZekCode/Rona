import AVFoundation
import Vision
import os
import UIKit

extension HandJoint {
    nonisolated var visionName: VNHumanHandPoseObservation.JointName {
        switch self {
        case .wrist: return .wrist
        case .thumbCMC: return .thumbCMC
        case .thumbMP: return .thumbMP
        case .thumbIP: return .thumbIP
        case .thumbTip: return .thumbTip
        case .indexMCP: return .indexMCP
        case .indexPIP: return .indexPIP
        case .indexTip: return .indexTip
        case .middleMCP: return .middleMCP
        case .middlePIP: return .middlePIP
        case .middleTip: return .middleTip
        case .ringMCP: return .ringMCP
        case .ringPIP: return .ringPIP
        case .ringTip: return .ringTip
        case .littleMCP: return .littleMCP
        case .littlePIP: return .littlePIP
        case .littleTip: return .littleTip
        }
    }
}

extension BodyJoint {
    nonisolated var visionName: VNHumanBodyPoseObservation.JointName {
        switch self {
        case .neck: return .neck
        case .leftShoulder: return .leftShoulder
        case .rightShoulder: return .rightShoulder
        case .leftElbow: return .leftElbow
        case .rightElbow: return .rightElbow
        case .leftWrist: return .leftWrist
        case .rightWrist: return .rightWrist
        case .leftHip: return .leftHip
        case .rightHip: return .rightHip
        }
    }
}

/// Runs the front camera and Vision's hand-pose detector, entirely on device. Camera frames are read here
/// and dropped; they never leave this class except as joint positions.
nonisolated final class HandTracker: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    enum Status: Sendable { case running, denied, unavailable }

    static let mirrored = true                // behave like a mirror

    let session = AVCaptureSession()
    /// The one live camera picture. Each page that shows it hosts this same layer, so the session is attached
    /// once: attaching a second preview layer to the running session blocked the main thread for 9 seconds
    /// in the prototype.
    let previewLayer = CameraPreviewLayer()
    /// Set before calling `start`. Delivered on the main actor once per processed frame.
    var onFrame: (@MainActor @Sendable (HandFrame) -> Void)?
    /// Set before calling `start`. Delivered once per processed frame while `bodyPoseEnabled` is on.
    var onBody: (@MainActor @Sendable (BodyFrame) -> Void)?
    /// Body pose costs frame time, so only the pages that need it (distance check, canvas) switch it on.
    var bodyPoseEnabled: Bool {
        get { bodyPoseFlag.withLock { $0 } }
        set { bodyPoseFlag.withLock { $0 = newValue } }
    }

    private let sessionQueue = DispatchQueue(label: "rona.camera.session")
    private let videoQueue = DispatchQueue(label: "rona.camera.video", qos: .userInteractive)
    private var configured = false
    private let bodyPoseFlag = OSAllocatedUnfairLock(initialState: false)
    private var rotation: AVCaptureDevice.RotationCoordinator?
    private var rotationObserver: NSKeyValueObservation?
    private let request: VNDetectHumanHandPoseRequest = {
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 2
        return request
    }()

    private let bodyRequest = VNDetectHumanBodyPoseRequest()

    override init() {
        super.init()
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
    }

    func start(completion: @escaping @MainActor @Sendable (Status) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            run(completion)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.run(completion)
                } else {
                    Task { @MainActor in completion(.denied) }
                }
            }
        default:
            Task { @MainActor in completion(.denied) }
        }
    }

    func stop() {
        sessionQueue.async {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    private func run(_ completion: @escaping @MainActor @Sendable (Status) -> Void) {
        sessionQueue.async {
            let ok = self.configureIfNeeded()
            if ok && !self.session.isRunning { self.session.startRunning() }
            Task { @MainActor in completion(ok ? .running : .unavailable) }
        }
    }

    private func configureIfNeeded() -> Bool {
        if configured { return true }
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                ?? AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return false }

        session.beginConfiguration()
        // Leave the audio session to the music engine.
        session.automaticallyConfiguresApplicationAudioSession = false
        // Arm's-length play makes hands small in the frame, so prefer 720p for reliable detection.
        if session.canSetSessionPreset(.hd1280x720) {
            session.sessionPreset = .hd1280x720
        } else if session.canSetSessionPreset(.vga640x480) {
            session.sessionPreset = .vga640x480
        }
        guard session.canAddInput(input) else {
            session.commitConfiguration()
            return false
        }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        output.setSampleBufferDelegate(self, queue: videoQueue)
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            return false
        }
        session.addOutput(output)

        // Upright, mirrored buffers: Vision coordinates then map straight onto the screen.
        if let connection = output.connection(with: .video) {
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = Self.mirrored
            }
            keepUpright(connection, device: device)
        }
        preferHighFrameRate(device)
        session.commitConfiguration()
        configured = true
        return true
    }

    /// The iPad is used in landscape on either side, and its camera sits on a different edge than the
    /// iPhone's, so the system says which way is up and we follow it when the iPad is turned around.
    private func keepUpright(_ connection: AVCaptureConnection, device: AVCaptureDevice) {
        let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: nil)
        rotation = coordinator
        let apply = { (angle: CGFloat) in
            if connection.isVideoRotationAngleSupported(angle) { connection.videoRotationAngle = angle }
        }
        apply(coordinator.videoRotationAngleForHorizonLevelCapture)
        rotationObserver = coordinator.observe(\.videoRotationAngleForHorizonLevelCapture) { [sessionQueue] coordinator, _ in
            let angle = coordinator.videoRotationAngleForHorizonLevelCapture
            sessionQueue.async { apply(angle) }
        }
    }

    /// Tracking at 60 fps roughly halves input latency. Falls back to the default 30 fps.
    private func preferHighFrameRate(_ device: AVCaptureDevice) {
        let candidates = device.formats.filter { format in
            let size = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            return size.width >= 1280 && size.width <= 1920
                && format.videoSupportedFrameRateRanges.contains { $0.maxFrameRate >= 60 }
        }
        guard let best = candidates.min(by: {
            CMVideoFormatDescriptionGetDimensions($0.formatDescription).width <
                CMVideoFormatDescriptionGetDimensions($1.formatDescription).width
        }) else { return }
        do {
            try device.lockForConfiguration()
            device.activeFormat = best
            device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 60)
            device.unlockForConfiguration()
        } catch {
            // Keep the default format.
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let aspect = Float(width) / Float(max(height, 1))
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])

        let wantsBody = bodyPoseEnabled
        var hands: [HandObservation] = []
        var body: BodyFrame?
        do {
            try handler.perform(wantsBody ? [request, bodyRequest] : [request])
            for observation in request.results ?? [] {
                guard let points = try? observation.recognizedPoints(.all) else { continue }
                var joints = [SIMD2<Float>?](repeating: nil, count: HandJoint.allCases.count)
                for joint in HandJoint.allCases {
                    guard let point = points[joint.visionName], point.confidence > 0.3 else { continue }
                    // Vision uses a bottom-left origin; flip to top-left.
                    joints[joint.rawValue] = SIMD2(Float(point.location.x), Float(1 - point.location.y))
                }
                hands.append(HandObservation(joints: joints, confidence: observation.confidence))
            }
            if wantsBody { body = bodyFrame(from: bodyRequest.results?.first, aspect: aspect) }
        } catch {
            // A failed frame is simply skipped.
        }

        let frame = HandFrame(hands: hands, imageAspect: aspect)
        let callback = onFrame
        let bodyCallback = onBody
        let bodyFrame = body ?? BodyFrame(points: Self.noBody, imageAspect: aspect)
        Task { @MainActor in
            callback?(frame)
            if wantsBody { bodyCallback?(bodyFrame) }
        }
    }

    private static let noBody = [BodyPoint?](repeating: nil, count: BodyJoint.allCases.count)

    private func bodyFrame(from observation: VNHumanBodyPoseObservation?, aspect: Float) -> BodyFrame {
        var points = Self.noBody
        if let observation, let recognized = try? observation.recognizedPoints(.all) {
            for joint in BodyJoint.allCases {
                guard let point = recognized[joint.visionName], point.confidence > 0.3 else { continue }
                points[joint.rawValue] = BodyPoint(location: SIMD2(Float(point.location.x), Float(1 - point.location.y)),
                                                   confidence: point.confidence)
            }
        }
        return BodyFrame(points: points, imageAspect: aspect)
    }
}
