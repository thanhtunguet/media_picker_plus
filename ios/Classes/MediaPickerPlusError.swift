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

    static func unsupportedOS() -> [String: Any] {
        return createError(code: .unsupportedOS, message: "Feature not supported on this iOS version")
    }

    private static func createError(code: MediaPickerPlusErrorCode, message: String) -> [String:
        Any]
    {
        return [
            "error": [
                "code": code.rawValue,
                "message": message,
            ]
        ]
    }
}

