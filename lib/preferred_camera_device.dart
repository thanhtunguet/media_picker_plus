enum PreferredCameraDevice {
  /// Let the platform decide the most suitable camera.
  auto,

  /// Prefer the front-facing (selfie) camera when available.
  front,

  /// Prefer the back-facing (environment) camera when available.
  back,
}
