import AVFoundation
import Cocoa
import FlutterMacOS
import Foundation
import Photos
import UniformTypeIdentifiers

// MARK: - Error Handling

public enum MediaPickerPlusErrorCode: String {
    case invalidArgs = "invalid_args"
    case invalidType = "invalid_type"
    case invalidSource = "invalid_source"
    case permissionDenied = "permission_denied"
    case saveFailed = "save_failed"
    case cancelled = "operation_cancelled"
    case unsupportedOS = "unsupported_os"
    case invalidImage = "invalid_image"
    case processingFailed = "processing_failed"
}

public struct MediaPickerPlusError {
    static func invalidArgs() -> FlutterError {
        return FlutterError(code: MediaPickerPlusErrorCode.invalidArgs.rawValue, 
                          message: "Invalid arguments", details: nil)
    }

    static func invalidType() -> FlutterError {
        return FlutterError(code: MediaPickerPlusErrorCode.invalidType.rawValue, 
                          message: "Invalid media type", details: nil)
    }

    static func invalidSource() -> FlutterError {
        return FlutterError(code: MediaPickerPlusErrorCode.invalidSource.rawValue, 
                          message: "Invalid media source", details: nil)
    }

    static func permissionDenied() -> FlutterError {
        return FlutterError(code: MediaPickerPlusErrorCode.permissionDenied.rawValue, 
                          message: "Permission denied", details: nil)
    }

    static func saveFailed() -> FlutterError {
        return FlutterError(code: MediaPickerPlusErrorCode.saveFailed.rawValue, 
                          message: "Failed to save media", details: nil)
    }

    static func cancelled() -> FlutterError {
        return FlutterError(code: MediaPickerPlusErrorCode.cancelled.rawValue, 
                          message: "User cancelled", details: nil)
    }

    static func unsupportedOS() -> FlutterError {
        return FlutterError(code: MediaPickerPlusErrorCode.unsupportedOS.rawValue, 
                          message: "Feature not supported on this OS version", details: nil)
    }

    static func invalidImage() -> FlutterError {
        return FlutterError(code: MediaPickerPlusErrorCode.invalidImage.rawValue, 
                          message: "Invalid image file", details: nil)
    }

    static func processingFailed() -> FlutterError {
        return FlutterError(code: MediaPickerPlusErrorCode.processingFailed.rawValue, 
                          message: "Image processing failed", details: nil)
    }
}

// MARK: - Watermark Position

/// Represents the position of a watermark in an image
public enum WatermarkPosition {
    /// Watermark positioned at the top left corner
    case topLeft

    /// Watermark positioned at the top center
    case topCenter

    /// Watermark positioned at the top right corner
    case topRight

    /// Watermark positioned at the middle left
    case middleLeft

    /// Watermark positioned at the center of the image
    case center

    /// Watermark positioned at the middle right
    case middleRight

    /// Watermark positioned at the bottom left corner
    case bottomLeft

    /// Watermark positioned at the bottom center
    case bottomCenter

    /// Watermark positioned at the bottom right corner
    case bottomRight

    /// Converts a string representation to a WatermarkPosition enum value
    /// - Parameter string: The string representation of the watermark position
    /// - Returns: The corresponding WatermarkPosition, or .center if the string doesn't match any case
    public static func fromString(_ string: String) -> WatermarkPosition {
        let lowercasedString = string.lowercased()

        switch lowercasedString {
        case "topleft", "top_left", "top-left":
            return .topLeft
        case "topcenter", "top_center", "top-center":
            return .topCenter
        case "topright", "top_right", "top-right":
            return .topRight
        case "middleleft", "middle_left", "middle-left":
            return .middleLeft
        case "center":
            return .center
        case "middleright", "middle_right", "middle-right":
            return .middleRight
        case "bottomleft", "bottom_left", "bottom-left":
            return .bottomLeft
        case "bottomcenter", "bottom_center", "bottom-center":
            return .bottomCenter
        case "bottomright", "bottom_right", "bottom-right":
            return .bottomRight
        default:
            return .center
        }
    }
}

public class MediaPickerPlusPlugin: NSObject, FlutterPlugin {
    private var pendingResult: FlutterResult?
    private var mediaOptions: [String: Any]?
    private var captureSession: AVCaptureSession?
    private var photoCaptureDelegate: PhotoCaptureDelegate?
    private var movieCaptureDelegate: MovieCaptureDelegate?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "info.thanhtunguet.media_picker_plus", binaryMessenger: registrar.messenger)
        let instance = MediaPickerPlusPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "pickMedia":
            guard let args = call.arguments as? [String: Any],
                  let source = args["source"] as? String,
                  let type = args["type"] as? String
            else {
                result(MediaPickerPlusError.invalidArgs())
                return
            }
            
            mediaOptions = args["options"] as? [String: Any]
            pendingResult = result
            
            switch source {
            case "gallery":
                // On macOS, no special permissions needed for NSOpenPanel
                switch type {
                case "image":
                    pickImageFromGallery()
                case "video":
                    pickVideoFromGallery()
                default:
                    result(MediaPickerPlusError.invalidType())
                }
            case "camera":
                if hasCameraPermission() {
                    switch type {
                    case "image":
                        capturePhoto()
                    case "video":
                        recordVideo()
                    default:
                        result(MediaPickerPlusError.invalidType())
                    }
                } else {
                    requestCameraPermission { granted in
                        if granted {
                            switch type {
                            case "image":
                                self.capturePhoto()
                            case "video":
                                self.recordVideo()
                            default:
                                result(MediaPickerPlusError.invalidType())
                            }
                        } else {
                            result(MediaPickerPlusError.permissionDenied())
                        }
                    }
                }
            default:
                result(MediaPickerPlusError.invalidSource())
            }
            
        case "hasCameraPermission":
            result(hasCameraPermission())
            
        case "hasGalleryPermission":
            result(hasGalleryPermission())
            
        case "requestCameraPermission":
            requestCameraPermission { granted in
                result(granted)
            }
            
        case "requestGalleryPermission":
            requestGalleryPermission { granted in
                result(granted)
            }
            
        case "pickFile":
            guard let args = call.arguments as? [String: Any] else {
                result(MediaPickerPlusError.invalidArgs())
                return
            }
            
            let allowedExtensions = args["allowedExtensions"] as? [String]
            pickFile(allowedExtensions: allowedExtensions) { path in
                result(path)
            }
            
        case "pickMultipleFiles":
            guard let args = call.arguments as? [String: Any] else {
                result(MediaPickerPlusError.invalidArgs())
                return
            }
            
            let allowedExtensions = args["allowedExtensions"] as? [String]
            pickMultipleFiles(allowedExtensions: allowedExtensions) { paths in
                result(paths)
            }
            
        case "processImage":
            guard let args = call.arguments as? [String: Any],
                  let imagePath = args["imagePath"] as? String else {
                result(MediaPickerPlusError.invalidArgs())
                return
            }
            
            let options = args["options"] as? [String: Any] ?? [:]
            processImage(imagePath: imagePath, options: options, result: result)
            
        case "addWatermarkToImage":
            guard let args = call.arguments as? [String: Any],
                  let imagePath = args["imagePath"] as? String else {
                result(MediaPickerPlusError.invalidArgs())
                return
            }
            
            let options = args["options"] as? [String: Any] ?? [:]
            addWatermarkToExistingImage(imagePath: imagePath, options: options, result: result)
            
        case "addWatermarkToVideo":
            guard let args = call.arguments as? [String: Any],
                  let videoPath = args["videoPath"] as? String else {
                result(MediaPickerPlusError.invalidArgs())
                return
            }
            
            let options = args["options"] as? [String: Any] ?? [:]
            addWatermarkToExistingVideo(videoPath: videoPath, options: options, result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Device Selection
    
    private func getBestAvailableVideoDevice() -> AVCaptureDevice? {
        // Try to get the best available video device, prioritizing newer device types
        // Handle different macOS versions gracefully
        
        if #available(macOS 14.0, *) {
            // First try Continuity Camera if available (macOS 14.0+)
            if let continuityCamera = AVCaptureDevice.default(.continuityCamera, for: .video, position: .unspecified) {
                return continuityCamera
            }
        }
        
        // Try built-in camera for supported macOS versions
        if #available(macOS 11.0, *) {
            if let builtInCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                return builtInCamera
            }
        }
        
        // Final fallback to any available video device (works on all macOS versions)
        return AVCaptureDevice.default(for: .video)
    }
    
    // MARK: - Permission Methods
    
    private func hasCameraPermission() -> Bool {
        // Camera permission check for all supported macOS versions
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        return status == .authorized
    }
    
    private func hasMicrophonePermission() -> Bool {
        // Microphone permission check for all supported macOS versions
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        return status == .authorized
    }
    
    private func hasGalleryPermission() -> Bool {
        // On macOS, different permission requirements based on version and access type
        if #available(macOS 11.0, *) {
            // macOS 11.0+ requires Photos library permission for programmatic access
            // But NSOpenPanel with user interaction doesn't require explicit permission
            // We'll check Photos permission if available, otherwise assume granted for file picker
            let photoLibraryStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            return photoLibraryStatus == .authorized || photoLibraryStatus == .limited
        } else {
            // macOS 10.x and earlier versions
            return true
        }
    }
    
    private func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        // Camera permission handling for all supported macOS versions
        if #available(macOS 11.0, *) {
            // macOS 11.0+ has more granular permission handling
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        } else {
            // For older macOS versions, still request permission but may not be strictly enforced
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        }
    }
    
    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        // Microphone permission handling for all supported macOS versions
        if #available(macOS 11.0, *) {
            // macOS 11.0+ has more granular permission handling
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        } else {
            // For older macOS versions, still request permission but may not be strictly enforced
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        }
    }
    
    private func requestGalleryPermission(completion: @escaping (Bool) -> Void) {
        // On macOS, handle permission requests based on version and access type
        if #available(macOS 11.0, *) {
            // For macOS 11.0+, request Photos library access for programmatic access
            // Note: NSOpenPanel with user interaction doesn't need explicit permission
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async {
                    completion(status == .authorized || status == .limited)
                }
            }
        } else {
            // For older macOS versions, no explicit permission needed
            DispatchQueue.main.async {
                completion(true)
            }
        }
    }
    
    // MARK: - Gallery Methods
    
    private func pickImageFromGallery() {
        // Use NSOpenPanel for file system access - this works across all macOS versions
        // and provides proper sandboxing without requiring explicit permissions
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Image"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        
        // Set allowed content types based on macOS version
        if #available(macOS 11.0, *) {
            openPanel.allowedContentTypes = [.image]
        } else {
            // For older macOS versions, use file extensions
            openPanel.allowedFileTypes = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic"]
        }
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                self.processSelectedImage(url: url)
            } else {
                self.pendingResult?(MediaPickerPlusError.cancelled())
                self.pendingResult = nil
            }
        }
    }
    
    private func pickVideoFromGallery() {
        // Use NSOpenPanel for file system access - this works across all macOS versions
        // and provides proper sandboxing without requiring explicit permissions
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Video"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        
        // Set allowed content types based on macOS version
        if #available(macOS 11.0, *) {
            openPanel.allowedContentTypes = [.movie]
        } else {
            // For older macOS versions, use file extensions
            openPanel.allowedFileTypes = ["mp4", "mov", "avi", "mkv", "m4v", "wmv"]
        }
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                self.processSelectedVideo(url: url)
            } else {
                self.pendingResult?(MediaPickerPlusError.cancelled())
                self.pendingResult = nil
            }
        }
    }
    
    // MARK: - Session Management
    
    private func cleanupCaptureSession() {
        captureSession?.stopRunning()
        captureSession = nil
        photoCaptureDelegate = nil
        movieCaptureDelegate = nil
    }
    
    // MARK: - Camera Methods
    
    private func capturePhoto() {
        print("Starting photo capture...")
        
        // Clean up any existing session
        cleanupCaptureSession()
        
        // Create new session
        captureSession = AVCaptureSession()
        guard let session = captureSession else { 
            print("Failed to create capture session")
            pendingResult?(MediaPickerPlusError.saveFailed())
            pendingResult = nil
            return
        }
        
        print("Getting video device...")
        guard let device = getBestAvailableVideoDevice() else {
            print("No video device available")
            pendingResult?(MediaPickerPlusError.saveFailed())
            pendingResult = nil
            return
        }
        
        print("Video device found: \(device.localizedName)")
        
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            print("Failed to create device input")
            pendingResult?(MediaPickerPlusError.saveFailed())
            pendingResult = nil
            return
        }
        
        print("Adding input to session...")
        if session.canAddInput(input) {
            session.addInput(input)
        } else {
            print("Cannot add input to session")
            pendingResult?(MediaPickerPlusError.saveFailed())
            pendingResult = nil
            return
        }
        
        let output = AVCapturePhotoOutput()
        print("Adding output to session...")
        if session.canAddOutput(output) {
            session.addOutput(output)
        } else {
            print("Cannot add output to session")
            pendingResult?(MediaPickerPlusError.saveFailed())
            pendingResult = nil
            return
        }
        
        // Retain the delegate as an instance variable
        photoCaptureDelegate = PhotoCaptureDelegate { [weak self] image in
            print("PhotoCaptureDelegate called with image: \(image != nil)")
            self?.cleanupCaptureSession()
            if let image = image {
                print("Processing captured image...")
                self?.processImage(image: image)
            } else {
                print("Photo capture delegate returned nil image")
                self?.pendingResult?(MediaPickerPlusError.saveFailed())
                self?.pendingResult = nil
            }
        }
        
        print("Starting capture session...")
        session.startRunning()
        
        // Add timeout mechanism
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            if self.pendingResult != nil {
                print("Photo capture timeout - stopping session")
                self.cleanupCaptureSession()
                self.pendingResult?(MediaPickerPlusError.saveFailed())
                self.pendingResult = nil
            }
        }
        
        // Wait longer for Continuity Camera to be ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            guard let delegate = self.photoCaptureDelegate else { 
                print("Photo capture delegate is nil")
                return 
            }
            
            print("Creating photo settings...")
            let settings = AVCapturePhotoSettings()
            print("Capturing photo with settings: \(settings)")
            output.capturePhoto(with: settings, delegate: delegate)
        }
    }
    
    private func recordVideo() {
        // Check microphone permission for video recording with audio
        if !hasMicrophonePermission() {
            requestMicrophonePermission { [weak self] granted in
                if granted {
                    self?.startVideoRecording()
                } else {
                    self?.pendingResult?(MediaPickerPlusError.permissionDenied())
                    self?.pendingResult = nil
                }
            }
        } else {
            startVideoRecording()
        }
    }
    
    private func startVideoRecording() {
        // Start recording immediately without blocking dialogs
        performVideoRecording()
    }
    
    private func performVideoRecording() {
        // Clean up any existing session
        cleanupCaptureSession()
        
        // Create new session
        captureSession = AVCaptureSession()
        guard let session = captureSession else { return }
        
        // Setup video input
        guard let videoDevice = getBestAvailableVideoDevice(),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            pendingResult?(MediaPickerPlusError.saveFailed())
            pendingResult = nil
            return
        }
        
        // Setup audio input
        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else {
            pendingResult?(MediaPickerPlusError.saveFailed())
            pendingResult = nil
            return
        }
        
        session.addInput(videoInput)
        session.addInput(audioInput)
        
        let output = AVCaptureMovieFileOutput()
        session.addOutput(output)
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("recorded_video_\(Date().timeIntervalSince1970).mov")
        
        // Retain the delegate as an instance variable
        movieCaptureDelegate = MovieCaptureDelegate { [weak self] url in
            print("MovieCaptureDelegate called with url: \(url?.absoluteString ?? "nil")")
            self?.cleanupCaptureSession()
            if let url = url {
                self?.processSelectedVideo(url: url)
            } else {
                self?.pendingResult?(MediaPickerPlusError.saveFailed())
                self?.pendingResult = nil
            }
        }
        
        session.startRunning()
        
        // Add timeout mechanism
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            if self.pendingResult != nil {
                print("Video recording timeout - stopping session")
                self.cleanupCaptureSession()
                self.pendingResult?(MediaPickerPlusError.saveFailed())
                self.pendingResult = nil
            }
        }
        
        // Wait longer for Continuity Camera to be ready, then start recording
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            guard let delegate = self.movieCaptureDelegate else { return }
            print("Starting video recording")
            output.startRecording(to: tempURL, recordingDelegate: delegate)
            
            // Auto-stop recording based on maxDuration or default to 30 seconds
            let maxDuration = (self.mediaOptions?["maxDuration"] as? Int) ?? 30
            print("Video recording will auto-stop after \(maxDuration) seconds")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(maxDuration)) {
                if output.isRecording {
                    print("Auto-stopping video recording after \(maxDuration) seconds")
                    output.stopRecording()
                }
            }
        }
    }
    
    // MARK: - Image Processing
    
    private func processSelectedImage(url: URL) {
        guard let image = NSImage(contentsOf: url) else {
            pendingResult?(MediaPickerPlusError.saveFailed())
            pendingResult = nil
            return
        }
        
        processImage(image: image)
    }
    
    private func processImage(image: NSImage) {
        print("Processing captured image with size: \(image.size)")
        var processedImage = image
        
        // Apply cropping if specified
        if let options = mediaOptions,
           let cropOptions = options["cropOptions"] as? [String: Any],
           let enableCrop = cropOptions["enableCrop"] as? Bool, enableCrop {
            print("Applying crop options: \(cropOptions)")
            processedImage = applyCropToImage(processedImage, cropOptions: cropOptions)
        }

        // Apply resizing if specified
        if let options = mediaOptions {
            print("Applying media options: \(options)")
            if let maxWidth = options["maxWidth"] as? Double,
               let maxHeight = options["maxHeight"] as? Double {
                print("Resizing image to max: \(maxWidth)x\(maxHeight)")
                processedImage = resizeImage(processedImage, maxWidth: maxWidth, maxHeight: maxHeight)
            }
            
            // Apply watermark if specified
            if let watermarkText = options["watermark"] as? String {
                let position = (options["watermarkPosition"] as? String) ?? "bottomRight"
                let fontSize = (options["watermarkFontSize"] as? Double) ?? 24.0
                print("Adding watermark: '\(watermarkText)' at position: \(position) with font size: \(fontSize)")
                processedImage = addWatermarkToImage(processedImage, text: watermarkText, position: position, fontSize: fontSize)
            }
        }
        
        // Save to temporary file
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp_image_\(Date().timeIntervalSince1970).jpg")
        print("Saving processed image to: \(tempURL.path)")
        
        if saveImage(processedImage, to: tempURL) {
            print("Successfully saved image to: \(tempURL.path)")
            pendingResult?(tempURL.path)
        } else {
            print("Failed to save image to temporary location")
            pendingResult?(MediaPickerPlusError.saveFailed())
        }
        
        pendingResult = nil
    }
    
    private func processSelectedVideo(url: URL) {
        // Check if we need to apply cropping or watermark
        let options = mediaOptions
        let watermarkText = options?["watermark"] as? String
        let cropOptions = options?["cropOptions"] as? [String: Any]
        let enableCrop = cropOptions?["enableCrop"] as? Bool ?? false
        
        if watermarkText != nil || enableCrop {
            let position = (options?["watermarkPosition"] as? String) ?? "bottomRight"
            let fontSize = (options?["watermarkFontSize"] as? Double) ?? 24.0
            print("Processing video with cropping and/or watermark")
            processVideoWithCropAndWatermark(url, 
                                           watermarkText: watermarkText, 
                                           position: position, 
                                           fontSize: fontSize,
                                           cropOptions: enableCrop ? cropOptions : nil) { [weak self] outputURL in
                if let outputURL = outputURL {
                    print("Video processing completed successfully: \(outputURL.path)")
                    self?.pendingResult?(outputURL.path)
                } else {
                    print("Video processing failed")
                    self?.pendingResult?(MediaPickerPlusError.saveFailed())
                }
                self?.pendingResult = nil
            }
        } else {
            print("No processing specified for video, returning original")
            pendingResult?(url.path)
            pendingResult = nil
        }
    }
    
    // MARK: - Watermark Utilities
    
    private func calculateOptimalFontSize(for dimensions: CGSize, requestedSize: Double, text: String) -> CGFloat {
        // Calculate font size as percentage of the smaller dimension
        // This ensures the watermark is proportional to the media size
        let minDimension = min(dimensions.width, dimensions.height)
        let maxDimension = max(dimensions.width, dimensions.height)
        
        // Base calculation: use requested size as percentage of smaller dimension
        let baseFontSize = minDimension * (requestedSize / 1000.0)
        
        // Apply bounds to ensure readability while preventing overflow
        let minFontSize: CGFloat = max(12.0, minDimension * 0.015) // Minimum 12pt or 1.5% of smaller dimension
        let maxFontSize: CGFloat = min(maxDimension * 0.08, minDimension * 0.15) // Max 8% of larger or 15% of smaller
        
        let calculatedSize = max(minFontSize, min(maxFontSize, baseFontSize))
        
        // Additional check: ensure text fits within 80% of the media width
        let tempAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: calculatedSize)
        ]
        let tempString = NSAttributedString(string: text, attributes: tempAttributes)
        let textWidth = tempString.size().width
        let maxAllowedWidth = dimensions.width * 0.8
        
        if textWidth > maxAllowedWidth {
            // Scale down font to fit within width
            let scaleFactor = maxAllowedWidth / textWidth
            return max(minFontSize, calculatedSize * scaleFactor)
        }
        
        print("Calculated optimal font size: \(calculatedSize) for dimensions: \(dimensions) (requested: \(requestedSize))")
        return calculatedSize
    }
    
    private func calculateWatermarkRect(
        for textSize: CGSize,
        in containerSize: CGSize,
        position: String,
        margin: CGFloat
    ) -> CGRect {
        // Ensure margin doesn't exceed available space
        let safeMargin = min(margin, min(containerSize.width, containerSize.height) * 0.05)
        
        // Ensure text size doesn't exceed container bounds
        let maxWidth = containerSize.width - (2 * safeMargin)
        let maxHeight = containerSize.height - (2 * safeMargin)
        let adjustedTextSize = CGSize(
            width: min(textSize.width, maxWidth),
            height: min(textSize.height, maxHeight)
        )
        
        var rect: CGRect
        
        switch position {
        case "topLeft":
            rect = CGRect(x: safeMargin, y: containerSize.height - adjustedTextSize.height - safeMargin, width: adjustedTextSize.width, height: adjustedTextSize.height)
        case "topCenter":
            rect = CGRect(x: (containerSize.width - adjustedTextSize.width) / 2, y: containerSize.height - adjustedTextSize.height - safeMargin, width: adjustedTextSize.width, height: adjustedTextSize.height)
        case "topRight":
            rect = CGRect(x: containerSize.width - adjustedTextSize.width - safeMargin, y: containerSize.height - adjustedTextSize.height - safeMargin, width: adjustedTextSize.width, height: adjustedTextSize.height)
        case "middleLeft":
            rect = CGRect(x: safeMargin, y: (containerSize.height - adjustedTextSize.height) / 2, width: adjustedTextSize.width, height: adjustedTextSize.height)
        case "middleCenter":
            rect = CGRect(x: (containerSize.width - adjustedTextSize.width) / 2, y: (containerSize.height - adjustedTextSize.height) / 2, width: adjustedTextSize.width, height: adjustedTextSize.height)
        case "middleRight":
            rect = CGRect(x: containerSize.width - adjustedTextSize.width - safeMargin, y: (containerSize.height - adjustedTextSize.height) / 2, width: adjustedTextSize.width, height: adjustedTextSize.height)
        case "bottomLeft":
            rect = CGRect(x: safeMargin, y: safeMargin, width: adjustedTextSize.width, height: adjustedTextSize.height)
        case "bottomCenter":
            rect = CGRect(x: (containerSize.width - adjustedTextSize.width) / 2, y: safeMargin, width: adjustedTextSize.width, height: adjustedTextSize.height)
        default: // bottomRight
            rect = CGRect(x: containerSize.width - adjustedTextSize.width - safeMargin, y: safeMargin, width: adjustedTextSize.width, height: adjustedTextSize.height)
        }
        
        // Final bounds check to ensure rect is within container
        rect.origin.x = max(0, min(rect.origin.x, containerSize.width - rect.size.width))
        rect.origin.y = max(0, min(rect.origin.y, containerSize.height - rect.size.height))
        
        return rect
    }
    
    // MARK: - Image Utilities
    
    private func resizeImage(_ image: NSImage, maxWidth: Double, maxHeight: Double) -> NSImage {
        let currentSize = image.size
        let widthRatio = maxWidth / currentSize.width
        let heightRatio = maxHeight / currentSize.height
        let ratio = min(widthRatio, heightRatio)
        
        if ratio >= 1.0 {
            return image
        }
        
        let newSize = NSSize(width: currentSize.width * ratio, height: currentSize.height * ratio)
        let newImage = NSImage(size: newSize)
        
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize))
        newImage.unlockFocus()
        
        return newImage
    }
    
    private func addWatermarkToImage(_ image: NSImage, text: String, position: String, fontSize: Double = 24.0) -> NSImage {
        let watermarkedImage = NSImage(size: image.size)
        
        // Calculate optimal font size based on image dimensions
        let optimalFontSize = calculateOptimalFontSize(for: image.size, requestedSize: fontSize, text: text)
        
        watermarkedImage.lockFocus()
        
        // Draw original image
        image.draw(in: NSRect(origin: .zero, size: image.size))
        
        // Setup text attributes with calculated font size
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: optimalFontSize),
            .foregroundColor: NSColor.white,
            .strokeColor: NSColor.black,
            .strokeWidth: -2
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        
        // Calculate position with bounds checking
        let imageSize = image.size
        let margin: CGFloat = max(20, imageSize.width * 0.02) // Dynamic margin based on image size
        let textRect = calculateWatermarkRect(for: textSize, in: imageSize, position: position, margin: margin)
        
        print("Watermark rect: \(textRect) for image size: \(imageSize)")
        attributedString.draw(in: textRect)
        
        watermarkedImage.unlockFocus()
        
        return watermarkedImage
    }
    
    private func saveImage(_ image: NSImage, to url: URL) -> Bool {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [:]) else {
            return false
        }
        
        do {
            try jpegData.write(to: url)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Video Utilities
    
    private func addWatermarkToVideo(_ inputURL: URL, text: String, position: String, fontSize: Double = 24.0, completion: @escaping (URL?) -> Void) {
        let asset = AVAsset(url: inputURL)
        let composition = AVMutableComposition()
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first,
              let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(nil)
            return
        }
        
        do {
            try compositionVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
        } catch {
            completion(nil)
            return
        }
        
        // Position text layer
        let videoSize = videoTrack.naturalSize
        
        // Calculate optimal font size for video
        let optimalFontSize = calculateOptimalFontSize(for: videoSize, requestedSize: fontSize, text: text)
        
        // Create text layer with calculated font size
        let textLayer = CATextLayer()
        textLayer.string = text
        textLayer.fontSize = optimalFontSize
        textLayer.foregroundColor = NSColor.white.cgColor
        textLayer.alignmentMode = .center
        
        // Calculate text size based on actual font size
        let tempAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: optimalFontSize)
        ]
        let tempString = NSAttributedString(string: text, attributes: tempAttributes)
        let calculatedTextSize = tempString.size()
        let textSize = CGSize(width: calculatedTextSize.width + 20, height: calculatedTextSize.height + 10) // Add padding
        
        let margin: CGFloat = max(20, videoSize.width * 0.02) // Dynamic margin based on video size
        
        // Calculate position with bounds checking
        let textRect = calculateWatermarkRect(for: textSize, in: videoSize, position: position, margin: margin)
        textLayer.frame = textRect
        
        print("Video watermark rect: \(textRect) for video size: \(videoSize)")
        
        // Create video layer
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: videoSize)
        
        // Create parent layer
        let parentLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: videoSize)
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(textLayer)
        
        // Create video composition
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        instruction.layerInstructions = [layerInstruction]
        
        videoComposition.instructions = [instruction]
        
        // Export
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("watermarked_video.mov")
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(nil)
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.videoComposition = videoComposition
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    completion(outputURL)
                default:
                    completion(nil)
                }
            }
        }
    }
    
    // MARK: - File Picker Methods
    
    private func pickFile(allowedExtensions: [String]?, completion: @escaping (String?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select File"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        
        // Set allowed file types based on macOS version
        if let extensions = allowedExtensions {
            if #available(macOS 11.0, *) {
                let utTypes = extensions.compactMap { ext in
                    let cleanExt = ext.hasPrefix(".") ? String(ext.dropFirst()) : ext
                    return UTType(filenameExtension: cleanExt)
                }
                openPanel.allowedContentTypes = utTypes
            } else {
                // For older macOS versions, use file extensions directly
                let cleanExtensions = extensions.map { ext in
                    ext.hasPrefix(".") ? String(ext.dropFirst()) : ext
                }
                openPanel.allowedFileTypes = cleanExtensions
            }
        }
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                completion(url.path)
            } else {
                completion(nil)
            }
        }
    }
    
    private func pickMultipleFiles(allowedExtensions: [String]?, completion: @escaping ([String]?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Files"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = true
        
        // Set allowed file types based on macOS version
        if let extensions = allowedExtensions {
            if #available(macOS 11.0, *) {
                let utTypes = extensions.compactMap { ext in
                    let cleanExt = ext.hasPrefix(".") ? String(ext.dropFirst()) : ext
                    return UTType(filenameExtension: cleanExt)
                }
                openPanel.allowedContentTypes = utTypes
            } else {
                // For older macOS versions, use file extensions directly
                let cleanExtensions = extensions.map { ext in
                    ext.hasPrefix(".") ? String(ext.dropFirst()) : ext
                }
                openPanel.allowedFileTypes = cleanExtensions
            }
        }
        
        openPanel.begin { response in
            if response == .OK {
                let paths = openPanel.urls.map { $0.path }
                completion(paths)
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - Cropping Methods
    
    private func applyCropToImage(_ image: NSImage, cropOptions: [String: Any]) -> NSImage {
        if let cropRect = cropOptions["cropRect"] as? [String: Any] {
            // Use specified crop rectangle
            let x = cropRect["x"] as? Double ?? 0
            let y = cropRect["y"] as? Double ?? 0
            let width = cropRect["width"] as? Double ?? Double(image.size.width)
            let height = cropRect["height"] as? Double ?? Double(image.size.height)
            
            let rect = CGRect(x: x, y: y, width: width, height: height)
            return cropImage(image, to: rect)
        } else if let aspectRatio = cropOptions["aspectRatio"] as? Double {
            // Apply aspect ratio cropping
            return applyCropWithAspectRatio(image, aspectRatio: CGFloat(aspectRatio))
        }
        
        return image
    }

    private func cropImage(_ image: NSImage, to rect: CGRect) -> NSImage {
        // Ensure crop bounds are within image bounds
        let imageSize = image.size
        let clampedRect = CGRect(
            x: max(0, min(rect.origin.x, imageSize.width)),
            y: max(0, min(rect.origin.y, imageSize.height)),
            width: min(rect.size.width, imageSize.width - max(0, rect.origin.x)),
            height: min(rect.size.height, imageSize.height - max(0, rect.origin.y))
        )
        
        guard clampedRect.width > 0 && clampedRect.height > 0 else {
            return image
        }
        
        let croppedImage = NSImage(size: clampedRect.size)
        croppedImage.lockFocus()
        
        let sourceRect = NSRect(
            x: clampedRect.origin.x,
            y: imageSize.height - clampedRect.origin.y - clampedRect.height, // Flip Y coordinate for NSImage
            width: clampedRect.width,
            height: clampedRect.height
        )
        
        let destRect = NSRect(origin: .zero, size: clampedRect.size)
        image.draw(in: destRect, from: sourceRect, operation: .copy, fraction: 1.0)
        
        croppedImage.unlockFocus()
        
        return croppedImage
    }

    private func applyCropWithAspectRatio(_ image: NSImage, aspectRatio: CGFloat) -> NSImage {
        let originalSize = image.size
        let originalAspectRatio = originalSize.width / originalSize.height

        let cropRect: CGRect

        if originalAspectRatio > aspectRatio {
            // Original is wider, crop width
            let newWidth = originalSize.height * aspectRatio
            let x = (originalSize.width - newWidth) / 2
            cropRect = CGRect(x: x, y: 0, width: newWidth, height: originalSize.height)
        } else {
            // Original is taller, crop height
            let newHeight = originalSize.width / aspectRatio
            let y = (originalSize.height - newHeight) / 2
            cropRect = CGRect(x: 0, y: y, width: originalSize.width, height: newHeight)
        }

        return cropImage(image, to: cropRect)
    }

    private func processVideoWithCropAndWatermark(
        _ inputURL: URL,
        watermarkText: String?,
        position: String,
        fontSize: Double = 24.0,
        cropOptions: [String: Any]?,
        completion: @escaping (URL?) -> Void
    ) {
        let asset = AVAsset(url: inputURL)
        let composition = AVMutableComposition()
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first,
              let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(nil)
            return
        }
        
        do {
            try compositionVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
        } catch {
            completion(nil)
            return
        }
        
        // Get original video size
        let originalVideoSize = videoTrack.naturalSize
        var finalVideoSize = originalVideoSize
        
        // Create video composition
        let videoComposition = AVMutableVideoComposition()
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        
        // Apply cropping if specified
        if let cropOptions = cropOptions {
            if let cropRect = cropOptions["cropRect"] as? [String: Any] {
                let x = cropRect["x"] as? Double ?? 0
                let y = cropRect["y"] as? Double ?? 0
                let width = cropRect["width"] as? Double ?? Double(originalVideoSize.width)
                let height = cropRect["height"] as? Double ?? Double(originalVideoSize.height)
                
                let rect = CGRect(x: x, y: y, width: width, height: height)
                let clampedRect = CGRect(
                    x: max(0, min(rect.origin.x, originalVideoSize.width)),
                    y: max(0, min(rect.origin.y, originalVideoSize.height)),
                    width: min(rect.size.width, originalVideoSize.width - max(0, rect.origin.x)),
                    height: min(rect.size.height, originalVideoSize.height - max(0, rect.origin.y))
                )
                
                if clampedRect.width > 0 && clampedRect.height > 0 {
                    finalVideoSize = clampedRect.size
                    let transform = CGAffineTransform(translationX: -clampedRect.origin.x, y: -clampedRect.origin.y)
                    layerInstruction.setTransform(transform, at: .zero)
                }
            } else if let aspectRatio = cropOptions["aspectRatio"] as? Double {
                let videoAspectRatio = originalVideoSize.width / originalVideoSize.height
                let targetAspectRatio = CGFloat(aspectRatio)
                
                if videoAspectRatio > targetAspectRatio {
                    // Video is wider, crop width
                    let newWidth = originalVideoSize.height * targetAspectRatio
                    let x = (originalVideoSize.width - newWidth) / 2
                    finalVideoSize = CGSize(width: newWidth, height: originalVideoSize.height)
                    let transform = CGAffineTransform(translationX: -x, y: 0)
                    layerInstruction.setTransform(transform, at: .zero)
                } else {
                    // Video is taller, crop height
                    let newHeight = originalVideoSize.width / targetAspectRatio
                    let y = (originalVideoSize.height - newHeight) / 2
                    finalVideoSize = CGSize(width: originalVideoSize.width, height: newHeight)
                    let transform = CGAffineTransform(translationX: 0, y: -y)
                    layerInstruction.setTransform(transform, at: .zero)
                }
            }
        }
        
        videoComposition.renderSize = finalVideoSize
        instruction.layerInstructions = [layerInstruction]
        
        // Add watermark if specified
        if let watermarkText = watermarkText, !watermarkText.isEmpty {
            // Calculate optimal font size for video
            let optimalFontSize = calculateOptimalFontSize(for: finalVideoSize, requestedSize: fontSize, text: watermarkText)
            
            // Create text layer with calculated font size
            let textLayer = CATextLayer()
            textLayer.string = watermarkText
            textLayer.fontSize = optimalFontSize
            textLayer.foregroundColor = NSColor.white.cgColor
            textLayer.alignmentMode = .center
            
            // Calculate text size based on actual font size
            let tempAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: optimalFontSize)
            ]
            let tempString = NSAttributedString(string: watermarkText, attributes: tempAttributes)
            let calculatedTextSize = tempString.size()
            let textSize = CGSize(width: calculatedTextSize.width + 20, height: calculatedTextSize.height + 10)
            
            let margin: CGFloat = max(20, finalVideoSize.width * 0.02)
            let textRect = calculateWatermarkRect(for: textSize, in: finalVideoSize, position: position, margin: margin)
            textLayer.frame = textRect
            
            // Create video layer
            let videoLayer = CALayer()
            videoLayer.frame = CGRect(origin: .zero, size: finalVideoSize)
            
            // Create parent layer
            let parentLayer = CALayer()
            parentLayer.frame = CGRect(origin: .zero, size: finalVideoSize)
            parentLayer.addSublayer(videoLayer)
            parentLayer.addSublayer(textLayer)
            
            videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        }
        
        videoComposition.instructions = [instruction]
        
        // Export
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("processed_video_\(Date().timeIntervalSince1970).mov")
        
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(nil)
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.videoComposition = videoComposition
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    completion(outputURL)
                default:
                    completion(nil)
                }
            }
        }
    }
    
    private func processImage(imagePath: String, options: [String: Any], result: @escaping FlutterResult) {
        guard let image = NSImage(contentsOfFile: imagePath) else {
            result(MediaPickerPlusError.invalidImage())
            return
        }
        
        var processedImage = image
        
        // Apply cropping if specified
        if let cropOptions = options["cropOptions"] as? [String: Any] {
            let enableCrop = cropOptions["enableCrop"] as? Bool ?? false
            if enableCrop {
                processedImage = applyCropToImage(processedImage, cropOptions: cropOptions)
            }
        }
        
        // Apply watermark if specified
        if let watermark = options["watermark"] as? String, !watermark.isEmpty {
            let watermarkFontSize = options["watermarkFontSize"] as? Double ?? 30.0
            let watermarkPosition = options["watermarkPosition"] as? String ?? "bottomRight"
            processedImage = addWatermarkToImage(processedImage, text: watermark, 
                                                 position: watermarkPosition, fontSize: watermarkFontSize)
        }
        
        // Apply quality and save
        let quality = (options["imageQuality"] as? Int ?? 80) / 100
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filename = "processed_\(Int(Date().timeIntervalSince1970)).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        guard let cgImage = processedImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            result(MediaPickerPlusError.processingFailed())
            return
        }
        
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let data = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: quality]) else {
            result(MediaPickerPlusError.processingFailed())
            return
        }
        
        do {
            try data.write(to: fileURL)
            result(fileURL.path)
        } catch {
            result(MediaPickerPlusError.processingFailed())
        }
    }
    
    private func addWatermarkToExistingImage(imagePath: String, options: [String: Any], result: @escaping FlutterResult) {
        // Validate input image path
        guard FileManager.default.fileExists(atPath: imagePath) else {
            result(MediaPickerPlusError.invalidImage())
            return
        }
        
        guard let image = NSImage(contentsOfFile: imagePath) else {
            result(MediaPickerPlusError.invalidImage())
            return
        }
        
        // Check if watermark is specified
        guard let watermarkText = options["watermark"] as? String, !watermarkText.isEmpty else {
            result(MediaPickerPlusError.invalidArgs())
            return
        }
        
        let fontSize = options["watermarkFontSize"] as? Double ?? 24.0
        let position = options["watermarkPosition"] as? String ?? "bottomRight"
        
        // Apply watermark to the image
        let watermarkedImage = addWatermarkToImage(image, text: watermarkText, position: position, fontSize: fontSize)
        
        // Save the watermarked image
        let quality = (options["imageQuality"] as? Int ?? 80) / 100
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filename = "watermarked_image_\(Int(Date().timeIntervalSince1970)).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        guard let cgImage = watermarkedImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            result(MediaPickerPlusError.processingFailed())
            return
        }
        
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let data = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: quality]) else {
            result(MediaPickerPlusError.processingFailed())
            return
        }
        
        do {
            try data.write(to: fileURL)
            result(fileURL.path)
        } catch {
            result(MediaPickerPlusError.processingFailed())
        }
    }
    
    private func addWatermarkToExistingVideo(videoPath: String, options: [String: Any], result: @escaping FlutterResult) {
        // Validate input video path
        guard FileManager.default.fileExists(atPath: videoPath) else {
            result(FlutterError(code: "INVALID_VIDEO", message: "Video file does not exist", details: nil))
            return
        }
        
        // Check if watermark is specified
        guard let watermarkText = options["watermark"] as? String, !watermarkText.isEmpty else {
            result(FlutterError(code: "INVALID_ARGS", message: "Watermark text is required", details: nil))
            return
        }
        
        let fontSize = options["watermarkFontSize"] as? Double ?? 24.0
        let position = options["watermarkPosition"] as? String ?? "bottomRight"
        
        let videoURL = URL(fileURLWithPath: videoPath)
        
        // Use the existing video watermarking method
        addWatermarkToVideo(videoURL, text: watermarkText, position: position, fontSize: fontSize) { outputURL in
            DispatchQueue.main.async {
                if let outputURL = outputURL {
                    result(outputURL.path)
                } else {
                    result(FlutterError(code: "PROCESSING_FAILED", message: "Failed to add watermark to video", details: nil))
                }
            }
        }
    }
}

// MARK: - Delegate Classes

class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (NSImage?) -> Void
    
    init(completion: @escaping (NSImage?) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("PhotoCaptureDelegate: didFinishProcessingPhoto called")
        
        if let error = error {
            print("Photo capture error: \(error.localizedDescription)")
            completion(nil)
            return
        }
        
        print("Photo captured successfully, processing data...")
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("Failed to get file data representation from photo")
            completion(nil)
            return
        }
        
        print("Got image data of size: \(imageData.count) bytes")
        
        guard let image = NSImage(data: imageData) else {
            print("Failed to create NSImage from image data")
            completion(nil)
            return
        }
        
        print("Successfully created NSImage with size: \(image.size)")
        completion(image)
    }
}

class MovieCaptureDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    private let completion: (URL?) -> Void
    
    init(completion: @escaping (URL?) -> Void) {
        self.completion = completion
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Video recording error: \(error)")
            completion(nil)
            return
        }
        
        completion(outputFileURL)
    }
}


