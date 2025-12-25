// Proof of Concept: Camera API Integration for Web
// This demonstrates the enhanced approach using getUserMedia, ImageCapture, and MediaRecorder

import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Helper class to detect browser capabilities
class BrowserCapabilities {
  /// Check if getUserMedia is supported
  static bool supportsGetUserMedia() {
    try {
      return web.window.navigator.mediaDevices != null;
    } catch (e) {
      return false;
    }
  }

  /// Check if ImageCapture API is supported
  static bool supportsImageCapture() {
    try {
      final hasImageCapture = web.window.hasProperty('ImageCapture'.toJS);
      return hasImageCapture;
    } catch (e) {
      return false;
    }
  }

  /// Check if MediaRecorder is supported
  static bool supportsMediaRecorder() {
    try {
      final hasMediaRecorder = web.window.hasProperty('MediaRecorder'.toJS);
      return hasMediaRecorder;
    } catch (e) {
      return false;
    }
  }

  /// Check if site is running in secure context (HTTPS or localhost)
  static bool isSecureContext() {
    return web.window.isSecureContext;
  }
}

/// Enhanced camera capture implementation
class CameraApiHelper {
  /// Request camera access and get MediaStream
  static Future<web.MediaStream?> getCameraStream({
    String facingMode =
        'environment', // 'user' for front, 'environment' for back
    int? width,
    int? height,
  }) async {
    if (!BrowserCapabilities.supportsGetUserMedia()) {
      return null;
    }

    if (!BrowserCapabilities.isSecureContext()) {
      print('Warning: getUserMedia requires HTTPS or localhost');
      return null;
    }

    try {
      final constraints = <String, dynamic>{
        'video': <String, dynamic>{
          'facingMode': facingMode,
          if (width != null) 'width': <String, dynamic>{'ideal': width},
          if (height != null) 'height': <String, dynamic>{'ideal': height},
        }.jsify(),
        'audio': false,
      }.jsify();

      final mediaDevices = web.window.navigator.mediaDevices;
      final streamPromise = mediaDevices.getUserMedia(constraints);
      final stream = await streamPromise.toDart as web.MediaStream;

      return stream;
    } catch (e) {
      print('Error getting camera stream: $e');
      return null;
    }
  }

  /// Capture photo using ImageCapture API
  static Future<web.Blob?> capturePhotoWithImageCapture(
    web.MediaStream stream,
  ) async {
    if (!BrowserCapabilities.supportsImageCapture()) {
      return null;
    }

    try {
      final videoTracks = stream.getVideoTracks().toDart;
      if (videoTracks.isEmpty) {
        return null;
      }

      final videoTrack = videoTracks[0] as web.MediaStreamTrack;

      // Create ImageCapture instance using JavaScript interop
      final imageCaptureClass = web.window.getProperty('ImageCapture'.toJS);
      final imageCapture =
          imageCaptureClass.callAsConstructor(videoTrack.jsify());

      // Call takePhoto method
      final takePhotoMethod =
          imageCapture.getProperty('takePhoto'.toJS) as JSFunction;
      final promise = takePhotoMethod.callAsFunction(imageCapture) as JSPromise;

      final blob = await promise.toDart as web.Blob;
      return blob;
    } catch (e) {
      print('Error capturing photo with ImageCapture: $e');
      return null;
    }
  }

  /// Fallback: Capture photo by drawing video frame to canvas
  static Future<web.Blob?> capturePhotoFromVideoElement(
    web.HTMLVideoElement videoElement,
  ) async {
    try {
      final canvas =
          web.document.createElement('canvas') as web.HTMLCanvasElement;
      canvas.width = videoElement.videoWidth;
      canvas.height = videoElement.videoHeight;

      final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
      ctx.drawImage(videoElement, 0, 0);

      final completer = Completer<web.Blob?>();

      canvas.toBlob(
          (web.Blob? blob) {
            completer.complete(blob);
          }.toJS,
          'image/jpeg'.toJS,
          0.95.toJS);

      return await completer.future;
    } catch (e) {
      print('Error capturing photo from video: $e');
      return null;
    }
  }

  /// Stop all tracks in a media stream
  static void stopMediaStream(web.MediaStream stream) {
    try {
      final tracks = stream.getTracks().toDart;
      for (final track in tracks) {
        (track as web.MediaStreamTrack).stop();
      }
    } catch (e) {
      print('Error stopping media stream: $e');
    }
  }
}

/// Video recording helper using MediaRecorder API
class MediaRecorderHelper {
  web.MediaRecorder? _recorder;
  final List<web.Blob> _chunks = [];
  final Completer<web.Blob?> _completer = Completer();

  /// Start recording
  Future<bool> startRecording(web.MediaStream stream) async {
    if (!BrowserCapabilities.supportsMediaRecorder()) {
      return false;
    }

    try {
      // Try video/webm first, fallback to default if not supported
      final options = <String, dynamic>{
        'mimeType': 'video/webm;codecs=vp9',
      }.jsify();

      _recorder = web.MediaRecorder(stream, options);

      _recorder!.addEventListener(
          'dataavailable',
          (web.Event event) {
            final blobEvent = event as web.BlobEvent;
            if (blobEvent.data != null && blobEvent.data!.size > 0) {
              _chunks.add(blobEvent.data!);
            }
          }.toJS);

      _recorder!.addEventListener(
          'stop',
          (web.Event event) {
            if (_chunks.isNotEmpty) {
              final blob = web.Blob(
                _chunks.toJS,
                web.BlobPropertyBag(type: 'video/webm'),
              );
              _completer.complete(blob);
            } else {
              _completer.complete(null);
            }
          }.toJS);

      _recorder!.start();
      return true;
    } catch (e) {
      print('Error starting recording: $e');
      return false;
    }
  }

  /// Stop recording and get the blob
  Future<web.Blob?> stopRecording() async {
    if (_recorder == null) {
      return null;
    }

    try {
      _recorder!.stop();
      return await _completer.future;
    } catch (e) {
      print('Error stopping recording: $e');
      return null;
    }
  }

  /// Check if currently recording
  bool get isRecording {
    return _recorder?.state == 'recording';
  }
}

/// Example usage in the main web implementation
class EnhancedCameraCapture {
  /// Capture photo with modern Camera API
  static Future<String?> capturePhotoModern() async {
    // Step 1: Check browser capabilities
    if (!BrowserCapabilities.supportsGetUserMedia()) {
      print('getUserMedia not supported, falling back to file input');
      return null; // Fall back to existing file input method
    }

    if (!BrowserCapabilities.isSecureContext()) {
      print('Not in secure context, falling back to file input');
      return null; // Fall back to existing file input method
    }

    web.MediaStream? stream;
    web.HTMLVideoElement? videoElement;

    try {
      // Step 2: Get camera stream
      stream = await CameraApiHelper.getCameraStream(
        facingMode: 'environment',
        width: 1920,
        height: 1080,
      );

      if (stream == null) {
        return null; // Fall back
      }

      // Step 3: Show camera preview
      videoElement =
          web.document.createElement('video') as web.HTMLVideoElement;
      videoElement.srcObject = stream;
      videoElement.autoplay = true;
      videoElement.playsInline = true;

      // Add to DOM (in real implementation, this would be in a Flutter overlay)
      web.document.body?.appendChild(videoElement);

      // Wait for video to be ready
      await Future.delayed(Duration(milliseconds: 500));

      // Step 4: Capture photo
      web.Blob? photoBlob;

      if (BrowserCapabilities.supportsImageCapture()) {
        // Try ImageCapture API first (best quality)
        photoBlob = await CameraApiHelper.capturePhotoWithImageCapture(stream);
      }

      if (photoBlob == null) {
        // Fallback to canvas snapshot
        photoBlob =
            await CameraApiHelper.capturePhotoFromVideoElement(videoElement);
      }

      if (photoBlob == null) {
        return null;
      }

      // Step 5: Convert blob to data URL
      final dataUrl = await _blobToDataUrl(photoBlob);

      return dataUrl;
    } finally {
      // Step 6: Cleanup
      if (stream != null) {
        CameraApiHelper.stopMediaStream(stream);
      }
      videoElement?.remove();
    }
  }

  /// Record video with modern Camera API
  static Future<String?> recordVideoModern() async {
    if (!BrowserCapabilities.supportsGetUserMedia() ||
        !BrowserCapabilities.supportsMediaRecorder()) {
      return null; // Fall back to file input
    }

    web.MediaStream? stream;
    web.HTMLVideoElement? videoElement;
    MediaRecorderHelper? recorder;

    try {
      // Get camera + microphone stream
      final constraints = <String, dynamic>{
        'video': <String, dynamic>{
          'facingMode': 'environment',
        }.jsify(),
        'audio': true, // Include audio for video recording
      }.jsify();

      final mediaDevices = web.window.navigator.mediaDevices;
      final streamPromise = mediaDevices.getUserMedia(constraints);
      stream = await streamPromise.toDart as web.MediaStream;

      // Show preview
      videoElement =
          web.document.createElement('video') as web.HTMLVideoElement;
      videoElement.srcObject = stream;
      videoElement.autoplay = true;
      videoElement.playsInline = true;
      videoElement.muted = true; // Mute preview to avoid feedback
      web.document.body?.appendChild(videoElement);

      // Start recording
      recorder = MediaRecorderHelper();
      final started = await recorder.startRecording(stream);

      if (!started) {
        return null;
      }

      // In real implementation, show recording UI with stop button
      // For now, just record for 5 seconds as example
      await Future.delayed(Duration(seconds: 5));

      // Stop recording
      final videoBlob = await recorder.stopRecording();

      if (videoBlob == null) {
        return null;
      }

      // Convert to URL
      final videoUrl = web.URL.createObjectURL(videoBlob);
      return videoUrl;
    } finally {
      if (stream != null) {
        CameraApiHelper.stopMediaStream(stream);
      }
      videoElement?.remove();
    }
  }

  /// Helper: Convert Blob to Data URL
  static Future<String> _blobToDataUrl(web.Blob blob) async {
    final completer = Completer<String>();
    final reader = web.FileReader();

    reader.addEventListener(
        'load',
        (web.Event event) {
          completer.complete(reader.result as String);
        }.toJS);

    reader.addEventListener(
        'error',
        (web.Event event) {
          completer.completeError('Failed to read blob');
        }.toJS);

    reader.readAsDataURL(blob);
    return await completer.future;
  }
}
