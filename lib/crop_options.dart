class CropRect {
  final double x;
  final double y;
  final double width;
  final double height;

  const CropRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }

  factory CropRect.fromMap(Map<String, dynamic> map) {
    return CropRect(
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      width: (map['width'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
    );
  }

  CropRect copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return CropRect(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  String toString() {
    return 'CropRect(x: $x, y: $y, width: $width, height: $height)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CropRect &&
        other.x == x &&
        other.y == y &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode {
    return x.hashCode ^ y.hashCode ^ width.hashCode ^ height.hashCode;
  }
}

class CropOptions {
  final CropRect? cropRect;
  final bool enableCrop;
  final double? aspectRatio;
  final bool freeform;
  final bool showGrid;
  final bool lockAspectRatio;

  const CropOptions({
    this.cropRect,
    this.enableCrop = false,
    this.aspectRatio,
    this.freeform = true,
    this.showGrid = true,
    this.lockAspectRatio = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'cropRect': cropRect?.toMap(),
      'enableCrop': enableCrop,
      'aspectRatio': aspectRatio,
      'freeform': freeform,
      'showGrid': showGrid,
      'lockAspectRatio': lockAspectRatio,
    };
  }

  factory CropOptions.fromMap(Map<String, dynamic> map) {
    return CropOptions(
      cropRect:
          map['cropRect'] != null ? CropRect.fromMap(map['cropRect']) : null,
      enableCrop: map['enableCrop'] ?? false,
      aspectRatio: map['aspectRatio']?.toDouble(),
      freeform: map['freeform'] ?? true,
      showGrid: map['showGrid'] ?? true,
      lockAspectRatio: map['lockAspectRatio'] ?? false,
    );
  }

  CropOptions copyWith({
    CropRect? cropRect,
    bool? enableCrop,
    double? aspectRatio,
    bool? freeform,
    bool? showGrid,
    bool? lockAspectRatio,
  }) {
    return CropOptions(
      cropRect: cropRect ?? this.cropRect,
      enableCrop: enableCrop ?? this.enableCrop,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      freeform: freeform ?? this.freeform,
      showGrid: showGrid ?? this.showGrid,
      lockAspectRatio: lockAspectRatio ?? this.lockAspectRatio,
    );
  }

  @override
  String toString() {
    return 'CropOptions(cropRect: $cropRect, enableCrop: $enableCrop, aspectRatio: $aspectRatio, freeform: $freeform, showGrid: $showGrid, lockAspectRatio: $lockAspectRatio)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CropOptions &&
        other.cropRect == cropRect &&
        other.enableCrop == enableCrop &&
        other.aspectRatio == aspectRatio &&
        other.freeform == freeform &&
        other.showGrid == showGrid &&
        other.lockAspectRatio == lockAspectRatio;
  }

  @override
  int get hashCode {
    return cropRect.hashCode ^
        enableCrop.hashCode ^
        aspectRatio.hashCode ^
        freeform.hashCode ^
        showGrid.hashCode ^
        lockAspectRatio.hashCode;
  }

  static const CropOptions square = CropOptions(
    enableCrop: true,
    aspectRatio: 1.0,
    lockAspectRatio: true,
    freeform: false,
  );

  static const CropOptions portrait = CropOptions(
    enableCrop: true,
    aspectRatio: 3.0 / 4.0,
    lockAspectRatio: true,
    freeform: false,
  );

  static const CropOptions landscape = CropOptions(
    enableCrop: true,
    aspectRatio: 4.0 / 3.0,
    lockAspectRatio: true,
    freeform: false,
  );

  static const CropOptions widescreen = CropOptions(
    enableCrop: true,
    aspectRatio: 16.0 / 9.0,
    lockAspectRatio: true,
    freeform: false,
  );
}
