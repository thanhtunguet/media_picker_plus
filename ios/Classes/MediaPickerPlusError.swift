import Flutter
import Foundation

public enum MediaPickerPlusErrorCode: String {
    case invalidArgs = "invalid_args"
    case invalidType = "invalid_type"
    case invalidSource = "invalid_source"
    case permissionDenied = "permission_denied"
    case saveFailed = "save_failed"
    case cancelled = "cancelled"
    case unsupportedOS = "unsupported_os"
    case invalidImage = "invalid_image"
    case processingFailed = "processing_failed"
}

public class MediaPickerPlusError {
    static func invalidArgs() -> FlutterError {
        return createError(code: .invalidArgs, message: "Invalid arguments")
    }

    static func invalidType() -> FlutterError {
        return createError(code: .invalidType, message: "Invalid media type")
    }

    static func invalidSource() -> FlutterError {
        return createError(code: .invalidSource, message: "Invalid media source")
    }

    static func permissionDenied() -> FlutterError {
        return createError(code: .permissionDenied, message: "Permission denied")
    }

    static func saveFailed() -> FlutterError {
        return createError(code: .saveFailed, message: "Failed to save media")
    }

    static func cancelled() -> FlutterError {
        return createError(code: .cancelled, message: "User cancelled")
    }

    static func unsupportedOS() -> FlutterError {
        return createError(code: .unsupportedOS, message: "Feature not supported on this iOS version")
    }

    static func invalidImage() -> FlutterError {
        return createError(code: .invalidImage, message: "Invalid image file")
    }

    static func processingFailed() -> FlutterError {
        return createError(code: .processingFailed, message: "Image processing failed")
    }

    private static func createError(code: MediaPickerPlusErrorCode, message: String) -> FlutterError {
        return FlutterError(code: code.rawValue, message: message, details: nil)
    }
}

