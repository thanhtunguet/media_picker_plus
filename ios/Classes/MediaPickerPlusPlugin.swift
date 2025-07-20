import AVFoundation
import Flutter
import Foundation
import MobileCoreServices
import Photos
import PhotosUI
import UIKit
import UniformTypeIdentifiers

public class MediaPickerPlusPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        // Delegate to the Swift implementation
        SwiftMediaPickerPlusPlugin.register(with: registrar)
    }
}

public class SwiftMediaPickerPlusPlugin: NSObject, FlutterPlugin, UIImagePickerControllerDelegate,
    UINavigationControllerDelegate, UIDocumentPickerDelegate, PHPickerViewControllerDelegate
{
    private var pendingResult: FlutterResult?
    private var mediaOptions: [String: Any]?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "info.thanhtunguet.media_picker_plus", binaryMessenger: registrar.messenger())
        let instance = SwiftMediaPickerPlusPlugin()
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
                        recordVideoWithPermissions()
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
                                self.recordVideoWithPermissions()
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

        case "pickFile":
            guard let args = call.arguments as? [String: Any] else {
                result(MediaPickerPlusError.invalidArgs())
                return
            }
            
            mediaOptions = args["options"] as? [String: Any]
            let allowedExtensions = args["allowedExtensions"] as? [String]
            pendingResult = result
            pickFile(allowedExtensions: allowedExtensions)

        case "pickMultipleFiles":
            guard let args = call.arguments as? [String: Any] else {
                result(MediaPickerPlusError.invalidArgs())
                return
            }
            
            mediaOptions = args["options"] as? [String: Any]
            let allowedExtensions = args["allowedExtensions"] as? [String]
            pendingResult = result
            pickMultipleFiles(allowedExtensions: allowedExtensions)

        case "pickMultipleMedia":
            guard let args = call.arguments as? [String: Any],
                let source = args["source"] as? String,
                let type = args["type"] as? String
            else {
                result(MediaPickerPlusError.invalidArgs())
                return
            }

            mediaOptions = args["options"] as? [String: Any]
            pendingResult = result
            pickMultipleMedia(source: source, type: type)
        case "processImage":
            guard let args = call.arguments as? [String: Any],
                  let imagePath = args["imagePath"] as? String else {
                result(MediaPickerPlusError.invalidArgs())
                return
            }
            
            let options = args["options"] as? [String: Any] ?? [:]
            processImage(imagePath: imagePath, options: options, result: result)

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

    private func hasMicrophonePermission() -> Bool {
        return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }

    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
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
            UIApplication.shared.windows.first?.rootViewController?.present(
                controller, animated: true, completion: nil)
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
                // Quality settings handled during processing, not here
                // just configuring basic picker settings
            }
        }

        presentPickerController(picker)
    }

    private func recordVideoWithPermissions() {
        // Check if microphone permission is granted
        if hasMicrophonePermission() {
            recordVideo()
        } else {
            requestMicrophonePermission { granted in
                if granted {
                    self.recordVideo()
                } else {
                    self.pendingResult?(MediaPickerPlusError.permissionDenied())
                    self.pendingResult = nil
                }
            }
        }
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
                if quality < 4_000_000 {
                    picker.videoQuality = .typeMedium
                } else if quality < 8_000_000 {
                    picker.videoQuality = .typeHigh
                } else {
                    picker.videoQuality = .typeHigh
                }
            }
            
            if let maxDuration = options["maxDuration"] as? Int {
                picker.videoMaximumDuration = TimeInterval(maxDuration)
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

        let tempDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            "media_\(timestamp)")

        do {
            try FileManager.default.createDirectory(
                at: tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
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
            var quality: CGFloat = 0.85  // Default Medium
            if let options = mediaOptions, let imageQuality = options["imageQuality"] as? Int {
                if imageQuality >= 90 {
                    quality = 0.9  // High
                } else if imageQuality >= 80 {
                    quality = 0.85  // Medium
                } else {
                    quality = 0.75  // Low
                }
            }

            // Process image size while preserving aspect ratio if specified
            var finalImage = image
            if let options = mediaOptions {
                if let maxWidth = options["maxWidth"] as? Int, maxWidth > 0,
                    let maxHeight = options["maxHeight"] as? Int, maxHeight > 0
                {

                    let originalSize = image.size
                    let widthRatio = CGFloat(maxWidth) / originalSize.width
                    let heightRatio = CGFloat(maxHeight) / originalSize.height
                    let ratio = min(widthRatio, heightRatio)

                    // Only resize if the image is larger than the max dimensions
                    if ratio < 1 {
                        let newSize = CGSize(
                            width: originalSize.width * ratio, height: originalSize.height * ratio)
                        // Print new size to console
                        print("Resizing image from \(originalSize) to \(newSize)")
                        // Resize the image
                        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
                        image.draw(in: CGRect(origin: .zero, size: newSize))
                        if let resizedImage = UIGraphicsGetImageFromCurrentImageContext() {
                            finalImage = resizedImage
                        }
                        UIGraphicsEndImageContext()
                    }
                }
            }

            // Apply cropping if specified
            if let options = mediaOptions, let cropOptions = options["cropOptions"] as? [String: Any],
               let enableCrop = cropOptions["enableCrop"] as? Bool, enableCrop {
                finalImage = applyCropToImage(finalImage, cropOptions: cropOptions)
            }

            // Add watermark if specified
            if let options = mediaOptions, let watermarkText = options["watermark"] as? String {
                finalImage = addWatermark(
                    to: finalImage,
                    text: watermarkText,
                    fontSize: options["watermarkFontSize"] as? CGFloat ?? 24,
                    position: options["watermarkPosition"] as? String ?? "bottomRight")
            }

            // Save image to temp directory
            if let data = finalImage.jpegData(compressionQuality: quality),
                let tempDir = createTempDirectory()
            {
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

                // Process video with cropping and/or watermark if specified
                if let options = mediaOptions {
                    let watermarkText = options["watermark"] as? String
                    let cropOptions = options["cropOptions"] as? [String: Any]
                    let enableCrop = cropOptions?["enableCrop"] as? Bool ?? false
                    
                    if watermarkText != nil || enableCrop {
                        let fontSize = options["watermarkFontSize"] as? CGFloat ?? 24
                        let position = options["watermarkPosition"] as? String ?? "bottomRight"

                        // First copy the video to the destination
                        do {
                            try FileManager.default.copyItem(at: videoURL, to: destinationURL)

                            // Then process video with cropping and/or watermark
                            return processVideoWithCropAndWatermark(
                                videoPath: destinationURL.path,
                                watermarkText: watermarkText,
                                fontSize: fontSize,
                                position: position,
                                cropOptions: enableCrop ? cropOptions : nil)
                        } catch {
                            print("Error copying video: \(error)")
                            return nil
                        }
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

    private func addWatermark(to image: UIImage, text: String, fontSize: CGFloat, position: String)
        -> UIImage
    {
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
            .paragraphStyle: paragraphStyle,
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
            point = CGPoint(
                x: (image.size.width - textSize.width) / 2,
                y: (image.size.height - textSize.height) / 2)
        case .middleRight:
            point = CGPoint(
                x: image.size.width - textSize.width - padding,
                y: (image.size.height - textSize.height) / 2)
        case .bottomLeft:
            point = CGPoint(x: padding, y: image.size.height - textSize.height - padding)
        case .bottomCenter:
            point = CGPoint(
                x: (image.size.width - textSize.width) / 2,
                y: image.size.height - textSize.height - padding)
        case .bottomRight:
            point = CGPoint(
                x: image.size.width - textSize.width - padding,
                y: image.size.height - textSize.height - padding)
        }

        // Draw the text
        text.draw(at: point, withAttributes: attributes)

        // Get the watermarked image
        let watermarkedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return watermarkedImage ?? image
    }

    private func processVideoWithCropAndWatermark(
        videoPath: String, 
        watermarkText: String?, 
        fontSize: CGFloat, 
        position: String,
        cropOptions: [String: Any]?
    ) -> String? {
        let asset = AVAsset(url: URL(fileURLWithPath: videoPath))
        let composition = AVMutableComposition()

        // Create video track
        guard let videoTrack = asset.tracks(withMediaType: .video).first,
            let compositionVideoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid)
        else {
            return videoPath  // Return original if can't process
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
                let compositionAudioTrack = compositionAudioTrack
            {
                try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
            }

            // Apply cropping if specified
            var videoComposition: AVMutableVideoComposition?
            var finalVideoSize: CGSize
            
            if let cropOptions = cropOptions {
                let (cropComposition, cropSize) = applyCropToVideo(
                    composition: composition, 
                    videoTrack: videoTrack, 
                    cropOptions: cropOptions
                )
                videoComposition = cropComposition
                finalVideoSize = cropSize
            } else {
                // Get original video size
                let transform = videoTrack.preferredTransform
                let isPortrait = abs(transform.b) == 1 && abs(transform.c) == 1
                finalVideoSize = isPortrait
                    ? CGSize(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.width)
                    : videoTrack.naturalSize
            }

            // Add watermark if specified
            if let watermarkText = watermarkText, !watermarkText.isEmpty {
                if videoComposition == nil {
                    videoComposition = AVMutableVideoComposition()
                    videoComposition?.renderSize = finalVideoSize
                    videoComposition?.frameDuration = CMTimeMake(value: 1, timescale: 30)
                    
                    let instruction = AVMutableVideoCompositionInstruction()
                    instruction.timeRange = timeRange
                    
                    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
                    layerInstruction.setTransform(videoTrack.preferredTransform, at: .zero)
                    
                    instruction.layerInstructions = [layerInstruction]
                    videoComposition?.instructions = [instruction]
                }
                
                // Add watermark layers
                videoComposition = addWatermarkToVideoComposition(
                    videoComposition: videoComposition!,
                    text: watermarkText,
                    fontSize: fontSize,
                    position: position,
                    videoSize: finalVideoSize
                )
            }

            // Export the processed video
            return exportProcessedVideo(
                composition: composition,
                videoComposition: videoComposition,
                originalPath: videoPath
            )

        } catch {
            print("Error processing video: \(error)")
            return videoPath  // Return original path if there was an error
        }
    }

    private func addWatermarkToVideo(
        videoPath: String, text: String, fontSize: CGFloat, position: String
    ) -> String? {
        let asset = AVAsset(url: URL(fileURLWithPath: videoPath))
        let composition = AVMutableComposition()

        // Create video track
        guard let videoTrack = asset.tracks(withMediaType: .video).first,
            let compositionVideoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid)
        else {
            return videoPath  // Return original if can't process
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
                let compositionAudioTrack = compositionAudioTrack
            {
                try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
            }

            // Get video size
            let transform = videoTrack.preferredTransform
            let isPortrait = abs(transform.b) == 1 && abs(transform.c) == 1
            let videoSize =
                isPortrait
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
                .paragraphStyle: paragraphStyle,
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
                textPosition = CGPoint(
                    x: (videoSize.width - textSize.width) / 2,
                    y: (videoSize.height - textSize.height) / 2)
            case .middleRight:
                textPosition = CGPoint(
                    x: videoSize.width - textSize.width - padding,
                    y: (videoSize.height - textSize.height) / 2)
            case .bottomLeft:
                textPosition = CGPoint(x: padding, y: videoSize.height - textSize.height - padding)
            case .bottomCenter:
                textPosition = CGPoint(
                    x: (videoSize.width - textSize.width) / 2,
                    y: videoSize.height - textSize.height - padding)
            case .bottomRight:
                textPosition = CGPoint(
                    x: videoSize.width - textSize.width - padding,
                    y: videoSize.height - textSize.height - padding)
            }

            // Create text layer
            let textLayer = CATextLayer()
            textLayer.string = text
            textLayer.font = CTFontCreateWithName(
                UIFont.boldSystemFont(ofSize: fontSize).fontName as CFString, fontSize, nil)
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

            let layerInstruction = AVMutableVideoCompositionLayerInstruction(
                assetTrack: compositionVideoTrack)

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
            let watermarkedVideoPath = documentsDirectory.appendingPathComponent(
                "VID_WM_\(timestamp).mp4"
            ).path
            let exportURL = URL(fileURLWithPath: watermarkedVideoPath)

            // Create and configure exporter
            guard
                let exporter = AVAssetExportSession(
                    asset: composition, presetName: AVAssetExportPresetHighestQuality)
            else {
                return videoPath  // Return original if can't create exporter
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
                return videoPath  // Return original if export fails
            }
        } catch {
            print("Error creating watermarked video: \(error)")
            return videoPath  // Return original path if there was an error
        }
    }

    private func pickFile(allowedExtensions: [String]?) {
        let documentPicker: UIDocumentPickerViewController
        
        if #available(iOS 14.0, *) {
            documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: getContentTypes(for: allowedExtensions))
        } else {
            documentPicker = UIDocumentPickerViewController(documentTypes: getDocumentTypes(for: allowedExtensions), in: .open)
        }
        
        documentPicker.delegate = self
        if #available(iOS 11.0, *) {
            documentPicker.allowsMultipleSelection = false
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.windows.first?.rootViewController?.present(
                documentPicker, animated: true, completion: nil)
        }
    }

    private func pickMultipleFiles(allowedExtensions: [String]?) {
        let documentPicker: UIDocumentPickerViewController
        
        if #available(iOS 14.0, *) {
            documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: getContentTypes(for: allowedExtensions))
        } else {
            documentPicker = UIDocumentPickerViewController(documentTypes: getDocumentTypes(for: allowedExtensions), in: .open)
        }
        
        documentPicker.delegate = self
        if #available(iOS 11.0, *) {
            documentPicker.allowsMultipleSelection = true
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.windows.first?.rootViewController?.present(
                documentPicker, animated: true, completion: nil)
        }
    }

    private func pickMultipleMedia(source: String, type: String) {
        // For iOS, we'll use PHPickerViewController for multiple selection
        if #available(iOS 14.0, *) {
            var config = PHPickerConfiguration()
            config.selectionLimit = 0 // 0 means unlimited
            
            switch type {
            case "image":
                config.filter = .images
            case "video":
                config.filter = .videos
            default:
                config.filter = .any(of: [.images, .videos])
            }
            
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            
            DispatchQueue.main.async {
                UIApplication.shared.windows.first?.rootViewController?.present(
                    picker, animated: true, completion: nil)
            }
        } else {
            // Fallback for older iOS versions - use single picker multiple times
            pendingResult?(MediaPickerPlusError.unsupportedOS())
        }
    }

    @available(iOS 14.0, *)
    private func getContentTypes(for extensions: [String]?) -> [UTType] {
        guard let extensions = extensions else {
            return [UTType.data] // Default to all files
        }
        
        var contentTypes: [UTType] = []
        for ext in extensions {
            switch ext.lowercased() {
            case "pdf":
                contentTypes.append(UTType.pdf)
            case "txt":
                contentTypes.append(UTType.text)
            case "doc", "docx":
                if let type = UTType(filenameExtension: ext) {
                    contentTypes.append(type)
                }
            case "xls", "xlsx":
                if let type = UTType(filenameExtension: ext) {
                    contentTypes.append(type)
                }
            case "jpg", "jpeg":
                contentTypes.append(UTType.jpeg)
            case "png":
                contentTypes.append(UTType.png)
            case "mp4":
                contentTypes.append(UTType.mpeg4Movie)
            case "mp3":
                contentTypes.append(UTType.mp3)
            default:
                if let type = UTType(filenameExtension: ext) {
                    contentTypes.append(type)
                }
            }
        }
        
        return contentTypes.isEmpty ? [UTType.data] : contentTypes
    }

    private func getDocumentTypes(for extensions: [String]?) -> [String] {
        guard let extensions = extensions else {
            return ["public.data"] // Default to all files
        }
        
        var documentTypes: [String] = []
        for ext in extensions {
            switch ext.lowercased() {
            case "pdf":
                documentTypes.append("com.adobe.pdf")
            case "txt":
                documentTypes.append("public.text")
            case "doc":
                documentTypes.append("com.microsoft.word.doc")
            case "docx":
                documentTypes.append("org.openxmlformats.wordprocessingml.document")
            case "xls":
                documentTypes.append("com.microsoft.excel.xls")
            case "xlsx":
                documentTypes.append("org.openxmlformats.spreadsheetml.sheet")
            case "jpg", "jpeg":
                documentTypes.append("public.jpeg")
            case "png":
                documentTypes.append("public.png")
            case "mp4":
                documentTypes.append("public.mpeg-4")
            case "mp3":
                documentTypes.append("public.mp3")
            default:
                documentTypes.append("public.data")
            }
        }
        
        return documentTypes.isEmpty ? ["public.data"] : documentTypes
    }

    // UIImagePickerControllerDelegate methods
    public func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
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

    // UIDocumentPickerDelegate methods
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: true) {
            var isMultipleSelection = false
            if #available(iOS 11.0, *) {
                isMultipleSelection = controller.allowsMultipleSelection
            }
            
            if isMultipleSelection {
                // Multiple files selected
                var filePaths: [String] = []
                for url in urls {
                    if url.startAccessingSecurityScopedResource() {
                        // Copy file to temp directory
                        if let tempPath = self.copyFileToTemp(from: url) {
                            filePaths.append(tempPath)
                        }
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                self.pendingResult?(filePaths)
            } else {
                // Single file selected
                if let url = urls.first {
                    if url.startAccessingSecurityScopedResource() {
                        let tempPath = self.copyFileToTemp(from: url)
                        self.pendingResult?(tempPath)
                        url.stopAccessingSecurityScopedResource()
                    } else {
                        self.pendingResult?(MediaPickerPlusError.saveFailed())
                    }
                } else {
                    self.pendingResult?(MediaPickerPlusError.saveFailed())
                }
            }
            self.pendingResult = nil
            self.mediaOptions = nil
        }
    }

    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true) {
            self.pendingResult?(MediaPickerPlusError.cancelled())
            self.pendingResult = nil
            self.mediaOptions = nil
        }
    }

    // PHPickerViewControllerDelegate methods
    @available(iOS 14.0, *)
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true) {
            if results.isEmpty {
                self.pendingResult?(MediaPickerPlusError.cancelled())
                self.pendingResult = nil
                self.mediaOptions = nil
                return
            }

            var filePaths: [String] = []
            let dispatchGroup = DispatchGroup()

            for result in results {
                dispatchGroup.enter()
                
                if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                        defer { dispatchGroup.leave() }
                        
                        if let image = object as? UIImage {
                            // Process image similar to imagePickerController
                            let info: [UIImagePickerController.InfoKey: Any] = [
                                .originalImage: image
                            ]
                            if let filePath = self.saveMediaToFile(info: info) {
                                filePaths.append(filePath)
                            }
                        }
                    }
                } else if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { (url, error) in
                        defer { dispatchGroup.leave() }
                        
                        if let url = url {
                            // Process video similar to imagePickerController
                            let info: [UIImagePickerController.InfoKey: Any] = [
                                .mediaURL: url
                            ]
                            if let filePath = self.saveMediaToFile(info: info) {
                                filePaths.append(filePath)
                            }
                        }
                    }
                } else {
                    dispatchGroup.leave()
                }
            }

            dispatchGroup.notify(queue: .main) {
                self.pendingResult?(filePaths)
                self.pendingResult = nil
                self.mediaOptions = nil
            }
        }
    }

    private func copyFileToTemp(from url: URL) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        
        let fileName = url.lastPathComponent
        let tempDir = FileManager.default.temporaryDirectory
        let destURL = tempDir.appendingPathComponent("FILE_\(timestamp)_\(fileName)")
        
        do {
            try FileManager.default.copyItem(at: url, to: destURL)
            return destURL.path
        } catch {
            print("Error copying file: \(error)")
            return nil
        }
    }

    private func applyCropToImage(_ image: UIImage, cropOptions: [String: Any]) -> UIImage {
        if let cropRect = cropOptions["cropRect"] as? [String: Any] {
            // Use specified crop rectangle - coordinates are normalized (0.0-1.0)
            let normalizedX = cropRect["x"] as? Double ?? 0
            let normalizedY = cropRect["y"] as? Double ?? 0
            let normalizedWidth = cropRect["width"] as? Double ?? 1.0
            let normalizedHeight = cropRect["height"] as? Double ?? 1.0
            
            // Get the CGImage to work with actual pixel dimensions
            guard let cgImage = image.cgImage else {
                return image
            }
            
            // Convert normalized coordinates to actual pixel coordinates based on CGImage dimensions
            let cgImageWidth = CGFloat(cgImage.width)
            let cgImageHeight = CGFloat(cgImage.height)
            
            let pixelX = normalizedX * Double(cgImageWidth)
            let pixelY = normalizedY * Double(cgImageHeight)
            let pixelWidth = normalizedWidth * Double(cgImageWidth)
            let pixelHeight = normalizedHeight * Double(cgImageHeight)
            
            let rect = CGRect(x: pixelX, y: pixelY, width: pixelWidth, height: pixelHeight)
            return cropImage(image, to: rect)
        } else if let aspectRatio = cropOptions["aspectRatio"] as? Double {
            // Apply aspect ratio cropping
            return applyCropWithAspectRatio(image, aspectRatio: CGFloat(aspectRatio))
        }
        
        return image
    }

    private func cropImage(_ image: UIImage, to rect: CGRect) -> UIImage {
        guard let cgImage = image.cgImage else {
            return image
        }
        
        // Ensure crop bounds are within CGImage bounds
        let cgImageWidth = CGFloat(cgImage.width)
        let cgImageHeight = CGFloat(cgImage.height)
        
        let clampedRect = CGRect(
            x: max(0, min(rect.origin.x, cgImageWidth)),
            y: max(0, min(rect.origin.y, cgImageHeight)),
            width: min(rect.size.width, cgImageWidth - max(0, rect.origin.x)),
            height: min(rect.size.height, cgImageHeight - max(0, rect.origin.y))
        )
        
        guard clampedRect.width > 0 && clampedRect.height > 0 else {
            return image
        }
        
        guard let croppedCGImage = cgImage.cropping(to: clampedRect) else {
            return image
        }
        
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }

    private func applyCropWithAspectRatio(_ image: UIImage, aspectRatio: CGFloat) -> UIImage {
        let originalSize = image.size
        let originalAspectRatio = originalSize.width / originalSize.height

        let newSize: CGSize
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

    private func applyCropToVideo(
        composition: AVMutableComposition,
        videoTrack: AVAssetTrack,
        cropOptions: [String: Any]
    ) -> (AVMutableVideoComposition?, CGSize) {
        let videoSize = videoTrack.naturalSize
        var cropRect: CGRect?
        
        if let cropRectData = cropOptions["cropRect"] as? [String: Any] {
            let x = cropRectData["x"] as? Double ?? 0
            let y = cropRectData["y"] as? Double ?? 0
            let width = cropRectData["width"] as? Double ?? Double(videoSize.width)
            let height = cropRectData["height"] as? Double ?? Double(videoSize.height)
            
            cropRect = CGRect(x: x, y: y, width: width, height: height)
        } else if let aspectRatio = cropOptions["aspectRatio"] as? Double {
            let videoAspectRatio = videoSize.width / videoSize.height
            let targetAspectRatio = CGFloat(aspectRatio)
            
            if videoAspectRatio > targetAspectRatio {
                // Video is wider, crop width
                let newWidth = videoSize.height * targetAspectRatio
                let x = (videoSize.width - newWidth) / 2
                cropRect = CGRect(x: x, y: 0, width: newWidth, height: videoSize.height)
            } else {
                // Video is taller, crop height
                let newHeight = videoSize.width / targetAspectRatio
                let y = (videoSize.height - newHeight) / 2
                cropRect = CGRect(x: 0, y: y, width: videoSize.width, height: newHeight)
            }
        }
        
        guard let finalCropRect = cropRect else {
            return (nil, videoSize)
        }
        
        // Create video composition with crop
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = finalCropRect.size
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
        
        if let compositionVideoTrack = composition.tracks(withMediaType: .video).first {
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
            
            // Apply crop transform
            let transform = CGAffineTransform(translationX: -finalCropRect.origin.x, y: -finalCropRect.origin.y)
            layerInstruction.setTransform(transform, at: .zero)
            
            instruction.layerInstructions = [layerInstruction]
        }
        
        videoComposition.instructions = [instruction]
        
        return (videoComposition, finalCropRect.size)
    }

    private func addWatermarkToVideoComposition(
        videoComposition: AVMutableVideoComposition,
        text: String,
        fontSize: CGFloat,
        position: String,
        videoSize: CGSize
    ) -> AVMutableVideoComposition {
        // Create watermark text attributes
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: fontSize),
            .foregroundColor: UIColor.white.withAlphaComponent(0.8),
            .strokeColor: UIColor.black,
            .strokeWidth: -2.0,
            .paragraphStyle: paragraphStyle,
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
            textPosition = CGPoint(
                x: (videoSize.width - textSize.width) / 2,
                y: (videoSize.height - textSize.height) / 2)
        case .middleRight:
            textPosition = CGPoint(
                x: videoSize.width - textSize.width - padding,
                y: (videoSize.height - textSize.height) / 2)
        case .bottomLeft:
            textPosition = CGPoint(x: padding, y: videoSize.height - textSize.height - padding)
        case .bottomCenter:
            textPosition = CGPoint(
                x: (videoSize.width - textSize.width) / 2,
                y: videoSize.height - textSize.height - padding)
        case .bottomRight:
            textPosition = CGPoint(
                x: videoSize.width - textSize.width - padding,
                y: videoSize.height - textSize.height - padding)
        }

        // Create text layer
        let textLayer = CATextLayer()
        textLayer.string = text
        textLayer.font = CTFontCreateWithName(
            UIFont.boldSystemFont(ofSize: fontSize).fontName as CFString, fontSize, nil)
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

        // Set custom compositor
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: parentLayer)

        return videoComposition
    }

    private func exportProcessedVideo(
        composition: AVMutableComposition,
        videoComposition: AVMutableVideoComposition?,
        originalPath: String
    ) -> String? {
        // Create export session
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())

        // Create a new destination for the processed video
        let documentsDirectory = FileManager.default.temporaryDirectory
        let processedVideoPath = documentsDirectory.appendingPathComponent(
            "VID_PROCESSED_\(timestamp).mp4"
        ).path
        let exportURL = URL(fileURLWithPath: processedVideoPath)

        // Create and configure exporter
        guard
            let exporter = AVAssetExportSession(
                asset: composition, presetName: AVAssetExportPresetHighestQuality)
        else {
            return originalPath  // Return original if can't create exporter
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
            try? FileManager.default.removeItem(atPath: originalPath)
            return processedVideoPath
        } else {
            print("Video export failed with error: \(String(describing: exporter.error))")
            return originalPath  // Return original if export fails
        }
    }
    
    private func processImage(imagePath: String, options: [String: Any], result: @escaping FlutterResult) {
        guard let image = UIImage(contentsOfFile: imagePath) else {
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
            processedImage = addWatermark(to: processedImage, text: watermark, 
                                          fontSize: CGFloat(watermarkFontSize), position: watermarkPosition)
        }
        
        // Apply quality and save
        let quality = (options["imageQuality"] as? Int ?? 80) / 100
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filename = "processed_\(Int(Date().timeIntervalSince1970)).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        guard let data = processedImage.jpegData(compressionQuality: CGFloat(quality)) else {
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
}
