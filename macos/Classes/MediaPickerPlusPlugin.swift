import AVFoundation
import Cocoa
import FlutterMacOS
import Foundation
import Photos
import UniformTypeIdentifiers

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
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Device Selection
    
    private func getBestAvailableVideoDevice() -> AVCaptureDevice? {
        // Try to get the best available video device, prioritizing newer device types
        
        if #available(macOS 14.0, *) {
            // First try Continuity Camera if available
            if let continuityCamera = AVCaptureDevice.default(.continuityCamera, for: .video, position: .unspecified) {
                return continuityCamera
            }
        }
        
        // Fall back to built-in camera
        if let builtInCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            return builtInCamera
        }
        
        // Final fallback to any available video device
        return AVCaptureDevice.default(for: .video)
    }
    
    // MARK: - Permission Methods
    
    private func hasCameraPermission() -> Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
    
    private func hasMicrophonePermission() -> Bool {
        return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }
    
    private func hasGalleryPermission() -> Bool {
        // On macOS, NSOpenPanel doesn't require special permissions
        // It uses the system's built-in file access permissions
        return true
    }
    
    private func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    private func requestGalleryPermission(completion: @escaping (Bool) -> Void) {
        // On macOS, NSOpenPanel handles file access permissions automatically
        // through the system's file access dialog. No explicit permission request needed.
        DispatchQueue.main.async {
            completion(true)
        }
    }
    
    // MARK: - Gallery Methods
    
    private func pickImageFromGallery() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Image"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [.image]
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                self.processSelectedImage(url: url)
            } else {
                self.pendingResult?(MediaPickerPlusError.operationCancelled())
                self.pendingResult = nil
            }
        }
    }
    
    private func pickVideoFromGallery() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Video"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [.movie]
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                self.processSelectedVideo(url: url)
            } else {
                self.pendingResult?(MediaPickerPlusError.operationCancelled())
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
            pendingResult?(MediaPickerPlusError.operationFailed())
            pendingResult = nil
            return
        }
        
        print("Getting video device...")
        guard let device = getBestAvailableVideoDevice() else {
            print("No video device available")
            pendingResult?(MediaPickerPlusError.cameraNotAvailable())
            pendingResult = nil
            return
        }
        
        print("Video device found: \(device.localizedName)")
        
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            print("Failed to create device input")
            pendingResult?(MediaPickerPlusError.cameraNotAvailable())
            pendingResult = nil
            return
        }
        
        print("Adding input to session...")
        if session.canAddInput(input) {
            session.addInput(input)
        } else {
            print("Cannot add input to session")
            pendingResult?(MediaPickerPlusError.operationFailed())
            pendingResult = nil
            return
        }
        
        let output = AVCapturePhotoOutput()
        print("Adding output to session...")
        if session.canAddOutput(output) {
            session.addOutput(output)
        } else {
            print("Cannot add output to session")
            pendingResult?(MediaPickerPlusError.operationFailed())
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
                self?.pendingResult?(MediaPickerPlusError.operationFailed())
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
                self.pendingResult?(MediaPickerPlusError.operationFailed())
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
            pendingResult?(MediaPickerPlusError.cameraNotAvailable())
            pendingResult = nil
            return
        }
        
        // Setup audio input
        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else {
            pendingResult?(MediaPickerPlusError.cameraNotAvailable())
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
                self?.pendingResult?(MediaPickerPlusError.operationFailed())
                self?.pendingResult = nil
            }
        }
        
        session.startRunning()
        
        // Add timeout mechanism
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            if self.pendingResult != nil {
                print("Video recording timeout - stopping session")
                self.cleanupCaptureSession()
                self.pendingResult?(MediaPickerPlusError.operationFailed())
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
            pendingResult?(MediaPickerPlusError.operationFailed())
            pendingResult = nil
            return
        }
        
        processImage(image: image)
    }
    
    private func processImage(image: NSImage) {
        print("Processing captured image with size: \(image.size)")
        var processedImage = image
        
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
            pendingResult?(MediaPickerPlusError.operationFailed())
        }
        
        pendingResult = nil
    }
    
    private func processSelectedVideo(url: URL) {
        // Apply watermark if specified
        if let options = mediaOptions,
           let watermarkText = options["watermark"] as? String {
            let position = (options["watermarkPosition"] as? String) ?? "bottomRight"
            let fontSize = (options["watermarkFontSize"] as? Double) ?? 24.0
            print("Adding watermark to video: '\(watermarkText)' at position: \(position) with font size: \(fontSize)")
            addWatermarkToVideo(url, text: watermarkText, position: position, fontSize: fontSize) { [weak self] outputURL in
                if let outputURL = outputURL {
                    print("Video watermark completed successfully: \(outputURL.path)")
                    self?.pendingResult?(outputURL.path)
                } else {
                    print("Video watermark failed")
                    self?.pendingResult?(MediaPickerPlusError.operationFailed())
                }
                self?.pendingResult = nil
            }
        } else {
            print("No watermark specified for video, returning original")
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
        
        // Set allowed file types
        if let extensions = allowedExtensions {
            let utTypes = extensions.compactMap { ext in
                let cleanExt = ext.hasPrefix(".") ? String(ext.dropFirst()) : ext
                return UTType(filenameExtension: cleanExt)
            }
            openPanel.allowedContentTypes = utTypes
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
        
        // Set allowed file types
        if let extensions = allowedExtensions {
            let utTypes = extensions.compactMap { ext in
                let cleanExt = ext.hasPrefix(".") ? String(ext.dropFirst()) : ext
                return UTType(filenameExtension: cleanExt)
            }
            openPanel.allowedContentTypes = utTypes
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

// MARK: - Error Handling

struct MediaPickerPlusError {
    static func invalidArgs() -> FlutterError {
        return FlutterError(code: "INVALID_ARGS", message: "Invalid arguments provided", details: nil)
    }
    
    static func invalidType() -> FlutterError {
        return FlutterError(code: "INVALID_TYPE", message: "Invalid media type", details: nil)
    }
    
    static func invalidSource() -> FlutterError {
        return FlutterError(code: "INVALID_SOURCE", message: "Invalid media source", details: nil)
    }
    
    static func permissionDenied() -> FlutterError {
        return FlutterError(code: "PERMISSION_DENIED", message: "Permission denied", details: nil)
    }
    
    static func operationCancelled() -> FlutterError {
        return FlutterError(code: "OPERATION_CANCELLED", message: "Operation cancelled by user", details: nil)
    }
    
    static func operationFailed() -> FlutterError {
        return FlutterError(code: "OPERATION_FAILED", message: "Operation failed", details: nil)
    }
    
    static func cameraNotAvailable() -> FlutterError {
        return FlutterError(code: "CAMERA_NOT_AVAILABLE", message: "Camera not available", details: nil)
    }
}
