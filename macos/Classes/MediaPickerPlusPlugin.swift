import AVFoundation
import Cocoa
import FlutterMacOS
import Foundation
import Photos
import UniformTypeIdentifiers

public class MediaPickerPlusPlugin: NSObject, FlutterPlugin {
    private var pendingResult: FlutterResult?
    private var mediaOptions: [String: Any]?
    
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
                if hasGalleryPermission() {
                    switch type {
                    case "image":
                        pickImageFromGallery()
                    case "video":
                        pickVideoFromGallery()
                    default:
                        result(MediaPickerPlusError.invalidType())
                    }
                } else {
                    requestGalleryPermission { granted in
                        if granted {
                            switch type {
                            case "image":
                                self.pickImageFromGallery()
                            case "video":
                                self.pickVideoFromGallery()
                            default:
                                result(MediaPickerPlusError.invalidType())
                            }
                        } else {
                            result(MediaPickerPlusError.permissionDenied())
                        }
                    }
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
    
    // MARK: - Permission Methods
    
    private func hasCameraPermission() -> Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
    
    private func hasGalleryPermission() -> Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }
    
    private func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    private func requestGalleryPermission(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
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
    
    // MARK: - Camera Methods
    
    private func capturePhoto() {
        // For macOS, we'll use a simple approach with AVCaptureSession
        // In a real implementation, you might want to show a preview window
        let captureSession = AVCaptureSession()
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            pendingResult?(MediaPickerPlusError.cameraNotAvailable())
            pendingResult = nil
            return
        }
        
        captureSession.addInput(input)
        
        let output = AVCapturePhotoOutput()
        captureSession.addOutput(output)
        
        let delegate = PhotoCaptureDelegate { [weak self] image in
            if let image = image {
                self?.processImage(image: image)
            } else {
                self?.pendingResult?(MediaPickerPlusError.operationFailed())
                self?.pendingResult = nil
            }
        }
        
        captureSession.startRunning()
        
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: delegate)
    }
    
    private func recordVideo() {
        // For macOS video recording, we'll use AVCaptureSession with AVCaptureMovieFileOutput
        let captureSession = AVCaptureSession()
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            pendingResult?(MediaPickerPlusError.cameraNotAvailable())
            pendingResult = nil
            return
        }
        
        captureSession.addInput(input)
        
        let output = AVCaptureMovieFileOutput()
        captureSession.addOutput(output)
        
        let delegate = MovieCaptureDelegate { [weak self] url in
            if let url = url {
                self?.processSelectedVideo(url: url)
            } else {
                self?.pendingResult?(MediaPickerPlusError.operationFailed())
                self?.pendingResult = nil
            }
        }
        
        captureSession.startRunning()
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp_video.mov")
        output.startRecording(to: tempURL, recordingDelegate: delegate)
        
        // For simplicity, we'll record for 10 seconds
        // In a real implementation, you'd want to show a UI to control recording
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            output.stopRecording()
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
        var processedImage = image
        
        // Apply resizing if specified
        if let options = mediaOptions {
            if let maxWidth = options["maxWidth"] as? Double,
               let maxHeight = options["maxHeight"] as? Double {
                processedImage = resizeImage(processedImage, maxWidth: maxWidth, maxHeight: maxHeight)
            }
            
            // Apply watermark if specified
            if let watermarkText = options["watermarkText"] as? String {
                let position = (options["watermarkPosition"] as? String) ?? "bottomRight"
                processedImage = addWatermarkToImage(processedImage, text: watermarkText, position: position)
            }
        }
        
        // Save to temporary file
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp_image.jpg")
        
        if saveImage(processedImage, to: tempURL) {
            pendingResult?([
                "path": tempURL.path,
                "width": processedImage.size.width,
                "height": processedImage.size.height
            ])
        } else {
            pendingResult?(MediaPickerPlusError.operationFailed())
        }
        
        pendingResult = nil
    }
    
    private func processSelectedVideo(url: URL) {
        // Apply watermark if specified
        if let options = mediaOptions,
           let watermarkText = options["watermarkText"] as? String {
            let position = (options["watermarkPosition"] as? String) ?? "bottomRight"
            addWatermarkToVideo(url, text: watermarkText, position: position) { [weak self] outputURL in
                if let outputURL = outputURL {
                    self?.pendingResult?([
                        "path": outputURL.path
                    ])
                } else {
                    self?.pendingResult?(MediaPickerPlusError.operationFailed())
                }
                self?.pendingResult = nil
            }
        } else {
            pendingResult?([
                "path": url.path
            ])
            pendingResult = nil
        }
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
    
    private func addWatermarkToImage(_ image: NSImage, text: String, position: String) -> NSImage {
        let watermarkedImage = NSImage(size: image.size)
        
        watermarkedImage.lockFocus()
        
        // Draw original image
        image.draw(in: NSRect(origin: .zero, size: image.size))
        
        // Setup text attributes
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24),
            .foregroundColor: NSColor.white,
            .strokeColor: NSColor.black,
            .strokeWidth: -2
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        
        // Calculate position
        let imageSize = image.size
        let margin: CGFloat = 20
        var textRect: NSRect
        
        switch position {
        case "topLeft":
            textRect = NSRect(x: margin, y: imageSize.height - textSize.height - margin, width: textSize.width, height: textSize.height)
        case "topCenter":
            textRect = NSRect(x: (imageSize.width - textSize.width) / 2, y: imageSize.height - textSize.height - margin, width: textSize.width, height: textSize.height)
        case "topRight":
            textRect = NSRect(x: imageSize.width - textSize.width - margin, y: imageSize.height - textSize.height - margin, width: textSize.width, height: textSize.height)
        case "middleLeft":
            textRect = NSRect(x: margin, y: (imageSize.height - textSize.height) / 2, width: textSize.width, height: textSize.height)
        case "middleCenter":
            textRect = NSRect(x: (imageSize.width - textSize.width) / 2, y: (imageSize.height - textSize.height) / 2, width: textSize.width, height: textSize.height)
        case "middleRight":
            textRect = NSRect(x: imageSize.width - textSize.width - margin, y: (imageSize.height - textSize.height) / 2, width: textSize.width, height: textSize.height)
        case "bottomLeft":
            textRect = NSRect(x: margin, y: margin, width: textSize.width, height: textSize.height)
        case "bottomCenter":
            textRect = NSRect(x: (imageSize.width - textSize.width) / 2, y: margin, width: textSize.width, height: textSize.height)
        default: // bottomRight
            textRect = NSRect(x: imageSize.width - textSize.width - margin, y: margin, width: textSize.width, height: textSize.height)
        }
        
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
    
    private func addWatermarkToVideo(_ inputURL: URL, text: String, position: String, completion: @escaping (URL?) -> Void) {
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
        
        // Create text layer
        let textLayer = CATextLayer()
        textLayer.string = text
        textLayer.fontSize = 24
        textLayer.foregroundColor = NSColor.white.cgColor
        textLayer.alignmentMode = .center
        
        // Position text layer
        let videoSize = videoTrack.naturalSize
        let margin: CGFloat = 20
        let textSize = CGSize(width: 200, height: 50)
        
        switch position {
        case "topLeft":
            textLayer.frame = CGRect(x: margin, y: videoSize.height - textSize.height - margin, width: textSize.width, height: textSize.height)
        case "topCenter":
            textLayer.frame = CGRect(x: (videoSize.width - textSize.width) / 2, y: videoSize.height - textSize.height - margin, width: textSize.width, height: textSize.height)
        case "topRight":
            textLayer.frame = CGRect(x: videoSize.width - textSize.width - margin, y: videoSize.height - textSize.height - margin, width: textSize.width, height: textSize.height)
        case "middleLeft":
            textLayer.frame = CGRect(x: margin, y: (videoSize.height - textSize.height) / 2, width: textSize.width, height: textSize.height)
        case "middleCenter":
            textLayer.frame = CGRect(x: (videoSize.width - textSize.width) / 2, y: (videoSize.height - textSize.height) / 2, width: textSize.width, height: textSize.height)
        case "middleRight":
            textLayer.frame = CGRect(x: videoSize.width - textSize.width - margin, y: (videoSize.height - textSize.height) / 2, width: textSize.width, height: textSize.height)
        case "bottomLeft":
            textLayer.frame = CGRect(x: margin, y: margin, width: textSize.width, height: textSize.height)
        case "bottomCenter":
            textLayer.frame = CGRect(x: (videoSize.width - textSize.width) / 2, y: margin, width: textSize.width, height: textSize.height)
        default: // bottomRight
            textLayer.frame = CGRect(x: videoSize.width - textSize.width - margin, y: margin, width: textSize.width, height: textSize.height)
        }
        
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
        if let error = error {
            print("Photo capture error: \(error)")
            completion(nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = NSImage(data: imageData) else {
            completion(nil)
            return
        }
        
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
