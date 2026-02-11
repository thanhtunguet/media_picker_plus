import AVFoundation
import Flutter
import UIKit

// Custom UIView that properly resizes the preview layer when bounds change
class CameraPreviewView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        // Update preview layer frame whenever the view's bounds change
        previewLayer?.frame = bounds
    }
}

class CameraViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    private var cameraChannel: FlutterMethodChannel

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        self.cameraChannel = FlutterMethodChannel(
            name: "info.thanhtunguet.media_picker_plus/camera",
            binaryMessenger: messenger
        )
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return CameraView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger,
            cameraChannel: cameraChannel
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class CameraView: NSObject, FlutterPlatformView {
    private enum BackLensMode {
        case wide
        case ultraWide
    }

    /// Generates a unique millisecond-precision timestamp for filenames.
    private static func generateTimestamp() -> Int {
        return Int(Date().timeIntervalSince1970 * 1000)
    }

    private var _view: CameraPreviewView
    private let previewLayer: AVCaptureVideoPreviewLayer
    private let captureSession: AVCaptureSession
    private var photoOutput: AVCapturePhotoOutput?
    private var cameraChannel: FlutterMethodChannel
    private var photoCaptureCompletion: ((String?) -> Void)?
    private var videoDevice: AVCaptureDevice?
    private var currentVideoInput: AVCaptureDeviceInput?
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    private var currentBackLensMode: BackLensMode = .wide

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger,
        cameraChannel: FlutterMethodChannel
    ) {
        captureSession = AVCaptureSession()
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        _view = CameraPreviewView(frame: frame)
        self.cameraChannel = cameraChannel

        super.init()

        // Add preview layer to view
        previewLayer.videoGravity = .resizeAspectFill
        _view.layer.addSublayer(previewLayer)
        _view.previewLayer = previewLayer

        setupCamera(args: args as? [String: Any])
        setupMethodChannel()
    }

    func view() -> UIView {
        return _view
    }

    private func setupCamera(args: [String: Any]?) {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo

        // Get camera device based on preferred device
        var cameraPosition: AVCaptureDevice.Position = .back
        if let preferredDevice = args?["preferredCameraDevice"] as? String {
            switch preferredDevice {
            case "front":
                cameraPosition = .front
            case "back":
                cameraPosition = .back
            default:
                cameraPosition = .back
            }
        }

        currentCameraPosition = cameraPosition
        currentBackLensMode = .wide

        guard let initialDevice = defaultVideoDevice(
            position: cameraPosition,
            backLensMode: .wide
        ) else {
            print("Failed to get camera device")
            return
        }

        // Store reference to video device for zoom control
        self.videoDevice = initialDevice

        do {
            let videoInput = try AVCaptureDeviceInput(device: initialDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                currentVideoInput = videoInput
            }

            // Add photo output
            photoOutput = AVCapturePhotoOutput()
            if let photoOutput = photoOutput, captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }

            captureSession.commitConfiguration()

            // Start session on background thread
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        } catch {
            print("Error setting up camera: \(error)")
        }
    }

    private func setupMethodChannel() {
        cameraChannel.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "capturePhoto":
                self?.capturePhoto { path in
                    result(path)
                }
            case "setZoom":
                if let args = call.arguments as? [String: Any],
                   let zoom = args["zoom"] as? Double {
                    self?.setZoom(CGFloat(zoom))
                    result(nil)
                } else {
                    result(FlutterError(
                        code: "INVALID_ARGUMENT",
                        message: "Zoom value required",
                        details: nil
                    ))
                }
            case "dispose":
                self?.dispose()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func capturePhoto(completion: @escaping (String?) -> Void) {
        guard let photoOutput = photoOutput else {
            completion(nil)
            return
        }

        photoCaptureCompletion = completion

        let settings = AVCapturePhotoSettings()
        // Use default settings - codec selection is automatic

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    private func setZoom(_ factor: CGFloat) {
        let resolvedFactor = switchBackLensIfNeeded(for: factor)

        guard let device = videoDevice else {
            print("No video device available for zoom")
            return
        }

        do {
            try device.lockForConfiguration()

            // Clamp zoom factor to device limits
            let clampedFactor = max(device.minAvailableVideoZoomFactor,
                                   min(resolvedFactor, device.maxAvailableVideoZoomFactor))

            device.videoZoomFactor = clampedFactor
            device.unlockForConfiguration()
        } catch {
            print("Error setting zoom: \(error)")
        }
    }

    private func defaultVideoDevice(
        position: AVCaptureDevice.Position,
        backLensMode: BackLensMode
    ) -> AVCaptureDevice? {
        if position == .back, backLensMode == .ultraWide {
            if #available(iOS 13.0, *) {
                if let ultraWide = AVCaptureDevice.default(
                    .builtInUltraWideCamera,
                    for: .video,
                    position: .back
                ) {
                    return ultraWide
                }
            }
        }

        if let wide = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: position
        ) {
            return wide
        }

        if position == .front {
            if #available(iOS 11.1, *) {
                return AVCaptureDevice.default(
                    .builtInTrueDepthCamera,
                    for: .video,
                    position: .front
                )
            }
        }

        return AVCaptureDevice.default(for: .video)
    }

    private func switchBackLensIfNeeded(for requestedFactor: CGFloat) -> CGFloat {
        guard currentCameraPosition == .back else {
            return requestedFactor
        }

        if requestedFactor < 1.0 {
            if currentBackLensMode != .ultraWide,
               let ultraWide = defaultVideoDevice(
                   position: .back,
                   backLensMode: .ultraWide
               ) {
                replaceCameraInput(with: ultraWide, backLensMode: .ultraWide)
            }

            // Native ultrawide sensor should run at its natural 1x zoom.
            return 1.0
        }

        if currentBackLensMode == .ultraWide,
           let wide = defaultVideoDevice(position: .back, backLensMode: .wide) {
            replaceCameraInput(with: wide, backLensMode: .wide)
        }

        return requestedFactor
    }

    private func replaceCameraInput(
        with device: AVCaptureDevice,
        backLensMode: BackLensMode
    ) {
        do {
            let newInput = try AVCaptureDeviceInput(device: device)

            captureSession.beginConfiguration()
            defer { captureSession.commitConfiguration() }

            let previousInput = currentVideoInput
            if let previousInput {
                captureSession.removeInput(previousInput)
            }

            guard captureSession.canAddInput(newInput) else {
                if let previousInput, captureSession.canAddInput(previousInput) {
                    captureSession.addInput(previousInput)
                }
                return
            }

            captureSession.addInput(newInput)
            currentVideoInput = newInput
            videoDevice = device
            currentBackLensMode = backLensMode
        } catch {
            print("Error switching camera lens: \(error)")
        }
    }

    private func dispose() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }
}

extension CameraView: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            print("Error capturing photo: \(error)")
            photoCaptureCompletion?(nil)
            return
        }

        guard let imageData = photo.fileDataRepresentation() else {
            photoCaptureCompletion?(nil)
            return
        }

        // Save to temp directory
        let tempDir = NSTemporaryDirectory()
        let fileName = "media_picker_plus_\(CameraView.generateTimestamp()).jpg"
        let filePath = (tempDir as NSString).appendingPathComponent(fileName)

        do {
            try imageData.write(to: URL(fileURLWithPath: filePath))
            photoCaptureCompletion?(filePath)
        } catch {
            print("Error saving photo: \(error)")
            photoCaptureCompletion?(nil)
        }
    }
}
