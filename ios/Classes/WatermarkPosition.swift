//
//  WatermarkPosition.swift
//  Runner
//
//  Created by Phạm Thanh Tùng on 3/4/25.
//

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
