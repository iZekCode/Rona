import AVFoundation

/// The camera picture shared by every page that shows it. It follows the iPad's rotation through one
/// coordinator for the whole app: a coordinator per hosting page piled up on the same layer.
nonisolated final class CameraPreviewLayer: AVCaptureVideoPreviewLayer {
    private var rotation: AVCaptureDevice.RotationCoordinator?
    private var rotationObserver: NSKeyValueObservation?

    /// Keeps the preview upright when the iPad is turned between the two landscape sides. Safe to call often.
    func followDeviceRotation() {
        if let rotation {
            apply(rotation.videoRotationAngleForHorizonLevelPreview)
            return
        }
        guard let device = (session?.inputs.first as? AVCaptureDeviceInput)?.device else { return }
        let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: self)
        rotation = coordinator
        apply(coordinator.videoRotationAngleForHorizonLevelPreview)
        rotationObserver = coordinator.observe(\.videoRotationAngleForHorizonLevelPreview) { [weak self] coordinator, _ in
            let angle = coordinator.videoRotationAngleForHorizonLevelPreview
            DispatchQueue.main.async { self?.apply(angle) }
        }
    }

    private func apply(_ angle: CGFloat) {
        guard let connection, connection.isVideoRotationAngleSupported(angle) else { return }
        connection.videoRotationAngle = angle
    }
}
