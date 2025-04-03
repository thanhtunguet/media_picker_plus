import Flutter
import UIKit
import Photos
import MobileCoreServices
import AVFoundation
import Foundation


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


public enum MediaPickerPlusErrorCode: String {
    case invalidArgs = "invalid_args"
    case invalidType = "invalid_type"
    case invalidSource = "invalid_source"
    case permissionDenied = "permission_denied"
    case saveFailed = "save_failed"
    case cancelled = "cancelled"
}

public class MediaPickerPlusError {
    static func invalidArgs() -> [String: Any] {
        return createError(code: .invalidArgs, message: "Invalid arguments")
    }
    
    static func invalidType() -> [String: Any] {
        return createError(code: .invalidType, message: "Invalid media type")
    }
    
    static func invalidSource() -> [String: Any] {
        return createError(code: .invalidSource, message: "Invalid media source")
    }
    
    static func permissionDenied() -> [String: Any] {
        return createError(code: .permissionDenied, message: "Permission denied")
    }
    
    static func saveFailed() -> [String: Any] {
        return createError(code: .saveFailed, message: "Failed to save media")
    }
    
    static func cancelled() -> [String: Any] {
        return createError(code: .cancelled, message: "User cancelled")
    }
    
    private static func createError(code: MediaPickerPlusErrorCode, message: String) -> [String: Any] {
        return [
            "error": [
                "code": code.rawValue,
                "message": message
            ]
        ]
    }
}

public class MediaPickerPlusPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        // Delegate to the Swift implementation
        SwiftMediaPickerPlusPlugin.register(with: registrar)
    }
}

public class SwiftMediaPickerPlusPlugin: NSObject, FlutterPlugin, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private var pendingResult: FlutterResult?
    private var mediaOptions: [String: Any]?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "info.thanhtunguet.media_picker_plus", binaryMessenger: registrar.messenger())
        let instance = SwiftMediaPickerPlusPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "pickMedia":
            guard let args = call.arguments as? [String: Any],
                  let source = args["source"] as? String,
                  let type = args["type"] as? String else {
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
            
        case "requestCameraPermission":
            requestCameraPermission { granted in
                result(granted)
            }
            
        case "hasGalleryPermission":
            result(hasGalleryPermission())
            
        case "requestGalleryPermission":
            requestGalleryPermission { granted in
                result(granted)
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func hasCameraPermission() -> Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
    
    private func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    private func hasGalleryPermission() -> Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }
    
    private func requestGalleryPermission(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }
    
    private func presentPickerController(_ controller: UIImagePickerController) {
        DispatchQueue.main.async {
            UIApplication.shared.windows.first?.rootViewController?.present(controller, animated: true, completion: nil)
        }
    }
    
    private func capturePhoto() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.mediaTypes = [kUTTypeImage as String]
        
        // Configure camera options
        if let options = mediaOptions {
            if let quality = options["imageQuality"] as? Int {
                picker.videoQuality = quality > 70 ? .typeHigh : .typeMedium
            }
        }
        
        presentPickerController(picker)
    }
    
    private func recordVideo() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.videoQuality = .typeHigh
        
        // Configure video options
        if let options = mediaOptions {
            if let quality = options["videoBitrate"] as? Int {
                if quality < 4000000 {
                    picker.videoQuality = .typeMedium
                } else if quality < 8000000 {
                    picker.videoQuality = .typeHigh
                } else {
                    picker.videoQuality = .typeHigh
                }
            }
        }
        
        presentPickerController(picker)
    }
    
    private func pickImageFromGallery() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [kUTTypeImage as String]
        presentPickerController(picker)
    }
    
    private func pickVideoFromGallery() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [kUTTypeMovie as String]
        presentPickerController(picker)
    }
    
    private func createTempDirectory() -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        
        let tempDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent("media_\(timestamp)")
        
        do {
            try FileManager.default.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            return tempDirectoryURL
        } catch {
            print("Error creating temp directory: \(error)")
            return nil
        }
    }
    
    private func saveMediaToFile(info: [UIImagePickerController.InfoKey: Any]) -> String? {
        // Create a unique filename based on timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        
        // Check if it's an image or video
        if let image = info[.originalImage] as? UIImage {
            // Process image quality if specified
            var quality: CGFloat = 0.8 // Default
            if let options = mediaOptions, let imageQuality = options["imageQuality"] as? Int {
                quality = CGFloat(imageQuality) / 100.0
            }
            
            // Process image size while preserving aspect ratio if specified
            var finalImage = image
            if let options = mediaOptions,
               let maxWidth = options["width"] as? Int,
               let maxHeight = options["height"] as? Int {
                
                let originalSize = image.size
                var newSize = originalSize
                
                // Calculate new size while preserving aspect ratio
                let widthRatio = CGFloat(maxWidth) / originalSize.width
                let heightRatio = CGFloat(maxHeight) / originalSize.height
                
                // Use the smaller ratio to ensure the image fits within the specified bounds
                let ratio = min(widthRatio, heightRatio)
                
                // Only resize if the image is larger than the specified dimensions
                if ratio < 1 {
                    newSize = CGSize(width: originalSize.width * ratio, height: originalSize.height * ratio)
                }
                
                UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                if let resizedImage = UIGraphicsGetImageFromCurrentImageContext() {
                    finalImage = resizedImage
                }
                UIGraphicsEndImageContext()
            }
            
            // Add watermark if specified
            if let options = mediaOptions, let watermarkText = options["watermark"] as? String {
                finalImage = addWatermark(to: finalImage,
                                          text: watermarkText,
                                          fontSize: options["watermarkFontSize"] as? CGFloat ?? 24,
                                          position: options["watermarkPosition"] as? String ?? "bottomRight")
            }
            
            // Save image to temp directory
            if let data = finalImage.jpegData(compressionQuality: quality),
               let tempDir = createTempDirectory() {
                let fileURL = tempDir.appendingPathComponent("IMG_\(timestamp).jpg")
                do {
                    try data.write(to: fileURL)
                    return fileURL.path
                } catch {
                    print("Error saving image: \(error)")
                    return nil
                }
            }
        } else if let videoURL = info[.mediaURL] as? URL {
            // Create destination URL in temp directory
            if let tempDir = createTempDirectory() {
                let destinationURL = tempDir.appendingPathComponent("VID_\(timestamp).mp4")
                
                // Add watermark to video if specified
                if let options = mediaOptions, let watermarkText = options["watermark"] as? String {
                    let fontSize = options["watermarkFontSize"] as? CGFloat ?? 24
                    let position = options["watermarkPosition"] as? String ?? "bottomRight"
                    
                    // First copy the video to the destination
                    do {
                        try FileManager.default.copyItem(at: videoURL, to: destinationURL)
                        
                        // Then add watermark and return the processed video path
                        return addWatermarkToVideo(videoPath: destinationURL.path,
                                                   text: watermarkText,
                                                   fontSize: fontSize,
                                                   position: position)
                    } catch {
                        print("Error copying video: \(error)")
                        return nil
                    }
                } else {
                    // Just copy the video file without watermark
                    do {
                        try FileManager.default.copyItem(at: videoURL, to: destinationURL)
                        return destinationURL.path
                    } catch {
                        print("Error copying video: \(error)")
                        return nil
                    }
                }
            }
        }
        
        return nil
    }
    
    private func addWatermark(to image: UIImage, text: String, fontSize: CGFloat, position: String) -> UIImage {
        // Create a new context with the same size as the image
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0.0)
        
        // Draw the original image
        image.draw(in: CGRect(origin: .zero, size: image.size))
        
        // Configure the text attributes
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: fontSize),
            .foregroundColor: UIColor.white.withAlphaComponent(0.8),
            .strokeColor: UIColor.black,
            .strokeWidth: -2.0,
            .paragraphStyle: paragraphStyle
        ]
        
        // Calculate text size
        let textSize = text.size(withAttributes: attributes)
        
        // Calculate position
        var point: CGPoint
        let padding: CGFloat = 20.0
        
        // Convert string position to WatermarkPosition enum
        let watermarkPosition: WatermarkPosition
        if position == "auto" {
            // Use longer edge
            if image.size.width > image.size.height {
                // Landscape, place on the right side
                watermarkPosition = .bottomRight
            } else {
                // Portrait, place on the bottom
                watermarkPosition = .bottomCenter
            }
        } else {
            watermarkPosition = WatermarkPosition.fromString(position)
        }
        
        // Determine point based on WatermarkPosition
        switch watermarkPosition {
        case .topLeft:
            point = CGPoint(x: padding, y: padding)
        case .topCenter:
            point = CGPoint(x: (image.size.width - textSize.width) / 2, y: padding)
        case .topRight:
            point = CGPoint(x: image.size.width - textSize.width - padding, y: padding)
        case .middleLeft:
            point = CGPoint(x: padding, y: (image.size.height - textSize.height) / 2)
        case .center:
            point = CGPoint(x: (image.size.width - textSize.width) / 2, y: (image.size.height - textSize.height) / 2)
        case .middleRight:
            point = CGPoint(x: image.size.width - textSize.width - padding, y: (image.size.height - textSize.height) / 2)
        case .bottomLeft:
            point = CGPoint(x: padding, y: image.size.height - textSize.height - padding)
        case .bottomCenter:
            point = CGPoint(x: (image.size.width - textSize.width) / 2, y: image.size.height - textSize.height - padding)
        case .bottomRight:
            point = CGPoint(x: image.size.width - textSize.width - padding, y: image.size.height - textSize.height - padding)
        }
        
        // Draw the text
        text.draw(at: point, withAttributes: attributes)
        
        // Get the watermarked image
        let watermarkedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return watermarkedImage ?? image
    }
    
    private func addWatermarkToVideo(videoPath: String, text: String, fontSize: CGFloat, position: String) -> String? {
        let asset = AVAsset(url: URL(fileURLWithPath: videoPath))
        let composition = AVMutableComposition()
        
        // Create video track
        guard let videoTrack = asset.tracks(withMediaType: .video).first,
              let compositionVideoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid) else {
            return videoPath // Return original if can't process
        }
        
        // Create audio track if present
        var compositionAudioTrack: AVMutableCompositionTrack?
        if let audioTrack = asset.tracks(withMediaType: .audio).first {
            compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid)
        }
        
        // Time range for the entire video
        let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
        
        do {
            // Add video track
            try compositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: .zero)
            
            // Add audio track if present
            if let audioTrack = asset.tracks(withMediaType: .audio).first,
               let compositionAudioTrack = compositionAudioTrack {
                try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
            }
            
            // Get video size
            let transform = videoTrack.preferredTransform
            let isPortrait = abs(transform.b) == 1 && abs(transform.c) == 1
            let videoSize = isPortrait
            ? CGSize(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.width)
            : videoTrack.naturalSize
            
            
            // Create watermark text attributes
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: fontSize),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8),
                .strokeColor: UIColor.black,
                .strokeWidth: -2.0,
                .paragraphStyle: paragraphStyle
            ]
            
            // Calculate text size
            let textSize = (text as NSString).size(withAttributes: attributes)
            
            // Calculate position
            var textPosition: CGPoint
            let padding: CGFloat = 20.0
            
            // Convert string position to WatermarkPosition enum
            let watermarkPosition: WatermarkPosition
            if position == "auto" {
                // Use longer edge
                if videoSize.width > videoSize.height {
                    // Landscape, place on the right side
                    watermarkPosition = .bottomRight
                } else {
                    // Portrait, place on the bottom
                    watermarkPosition = .bottomCenter
                }
            } else {
                watermarkPosition = WatermarkPosition.fromString(position)
            }
            
            // Determine point based on WatermarkPosition
            switch watermarkPosition {
            case .topLeft:
                textPosition = CGPoint(x: padding, y: padding)
            case .topCenter:
                textPosition = CGPoint(x: (videoSize.width - textSize.width) / 2, y: padding)
            case .topRight:
                textPosition = CGPoint(x: videoSize.width - textSize.width - padding, y: padding)
            case .middleLeft:
                textPosition = CGPoint(x: padding, y: (videoSize.height - textSize.height) / 2)
            case .center:
                textPosition = CGPoint(x: (videoSize.width - textSize.width) / 2, y: (videoSize.height - textSize.height) / 2)
            case .middleRight:
                textPosition = CGPoint(x: videoSize.width - textSize.width - padding, y: (videoSize.height - textSize.height) / 2)
            case .bottomLeft:
                textPosition = CGPoint(x: padding, y: videoSize.height - textSize.height - padding)
            case .bottomCenter:
                textPosition = CGPoint(x: (videoSize.width - textSize.width) / 2, y: videoSize.height - textSize.height - padding)
            case .bottomRight:
                textPosition = CGPoint(x: videoSize.width - textSize.width - padding, y: videoSize.height - textSize.height - padding)
            }
            
            // Create text layer
            let textLayer = CATextLayer()
            textLayer.string = text
            textLayer.font = CTFontCreateWithName(UIFont.boldSystemFont(ofSize: fontSize).fontName as CFString, fontSize, nil)
            textLayer.fontSize = fontSize
            textLayer.foregroundColor = UIColor.white.cgColor
            textLayer.alignmentMode = .center
            textLayer.backgroundColor = UIColor.clear.cgColor
            textLayer.frame = CGRect(origin: textPosition, size: textSize)
            
            // Create parent layer
            let parentLayer = CALayer()
            let videoLayer = CALayer()
            parentLayer.frame = CGRect(origin: .zero, size: videoSize)
            videoLayer.frame = CGRect(origin: .zero, size: videoSize)
            
            // Add text and video layers to parent layer
            parentLayer.addSublayer(videoLayer)
            parentLayer.addSublayer(textLayer)
            
            // Create video composition
            let videoComposition = AVMutableVideoComposition()
            videoComposition.renderSize = videoSize
            videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
            
            // Add instruction to video composition
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = timeRange
            
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
            
            // Apply any transforms from the original video
            layerInstruction.setTransform(transform, at: .zero)
            
            instruction.layerInstructions = [layerInstruction]
            videoComposition.instructions = [instruction]
            
            // Set custom compositor
            videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
                postProcessingAsVideoLayer: videoLayer,
                in: parentLayer)
            
            // Create export session
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestamp = formatter.string(from: Date())
            
            // Create a new destination for the watermarked video
            let documentsDirectory = FileManager.default.temporaryDirectory
            let watermarkedVideoPath = documentsDirectory.appendingPathComponent("VID_WM_\(timestamp).mp4").path
            let exportURL = URL(fileURLWithPath: watermarkedVideoPath)
            
            // Create and configure exporter
            guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
                return videoPath // Return original if can't create exporter
            }
            
            exporter.outputURL = exportURL
            exporter.outputFileType = .mp4
            exporter.videoComposition = videoComposition
            
            // Export video synchronously
            let exportSemaphore = DispatchSemaphore(value: 0)
            
            exporter.exportAsynchronously {
                exportSemaphore.signal()
            }
            
            // Wait for export to complete
            _ = exportSemaphore.wait(timeout: .distantFuture)
            
            if exporter.status == .completed {
                // Delete the original file since we've created a new one
                try FileManager.default.removeItem(atPath: videoPath)
                return watermarkedVideoPath
            } else {
                print("Video export failed with error: \(String(describing: exporter.error))")
                return videoPath // Return original if export fails
            }
        } catch {
            print("Error creating watermarked video: \(error)")
            return videoPath // Return original path if there was an error
        }
    }
    
    // UIImagePickerControllerDelegate methods
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true) {
            if let filePath = self.saveMediaToFile(info: info) {
                self.pendingResult?(filePath)
            } else {
                self.pendingResult?(MediaPickerPlusError.saveFailed())
            }
            self.pendingResult = nil
            self.mediaOptions = nil
        }
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) {
            self.pendingResult?(MediaPickerPlusError.cancelled())
            self.pendingResult = nil
            self.mediaOptions = nil
        }
    }
}
