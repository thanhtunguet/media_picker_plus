/// Represents the position of a watermark on a media.
///
/// This abstract class serves as a base for defining different watermark positions.
/// Implementations of this class should specify how a watermark is positioned
/// (e.g., top-left, center, bottom-right) on the media being edited.
abstract class WatermarkPosition {
  static const String topLeft = 'topLeft';
  static const String topRight = 'topRight';
  static const String bottomLeft = 'bottomLeft';
  static const String bottomRight = 'bottomRight';
}
