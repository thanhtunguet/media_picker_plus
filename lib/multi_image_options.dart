/// Options for multi-image picking operations (camera multi-capture and
/// gallery multi-select).
class MultiImageOptions {
  /// Maximum number of images the user can select/capture.
  /// When `null`, there is no limit.
  final int? maxImages;

  /// Minimum number of images required before the user can confirm.
  /// Defaults to 1.
  final int minImages;

  /// Whether to show a confirmation dialog when the user tries to discard
  /// captured photos by pressing back.
  /// Defaults to `true`.
  final bool confirmOnDiscard;

  const MultiImageOptions({
    this.maxImages,
    this.minImages = 1,
    this.confirmOnDiscard = true,
  });
}
