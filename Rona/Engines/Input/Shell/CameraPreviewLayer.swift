import AVFoundation

// The one camera picture shared by every page, with one rotation coordinator for the whole app.
nonisolated final class CameraPreviewLayer: AVCaptureVideoPreviewLayer {
    private var rotation: AVCaptureDevice.RotationCoordinator?
    private var rotationObserver: NSKeyValueObservation?

    // Keeps the preview upright on both landscape sides; safe to call often.
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
