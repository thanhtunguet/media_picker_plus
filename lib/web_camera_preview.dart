import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Camera preview UI controller for web
class WebCameraPreview {
  web.HTMLDivElement? _container;
  web.HTMLVideoElement? _video;
  web.HTMLButtonElement? _captureButton;
  web.HTMLButtonElement? _cancelButton;
  web.HTMLDivElement? _recordingIndicator;
  Timer? _timer;
  int _elapsedSeconds = 0;

  /// Show camera preview with capture/record controls
  Future<bool?> show({
    required web.MediaStream stream,
    required bool isVideo,
  }) async {
    final completer = Completer<bool?>();

    // Create container
    _container = web.document.createElement('div') as web.HTMLDivElement;
    _container!.style.cssText = '''
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background: rgba(0, 0, 0, 0.95);
      z-index: 9999;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
    ''';

    // Create video element
    _video = web.document.createElement('video') as web.HTMLVideoElement;
    _video!.srcObject = stream;
    _video!.autoplay = true;
    _video!.playsInline = true;
    _video!.muted = true;
    _video!.style.cssText = '''
      max-width: 90%;
      max-height: 70vh;
      border-radius: 12px;
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
    ''';

    // Create top bar
    final topBar = web.document.createElement('div') as web.HTMLDivElement;
    topBar.style.cssText = '''
      position: absolute;
      top: 0;
      left: 0;
      right: 0;
      padding: 20px;
      background: linear-gradient(to bottom, rgba(0,0,0,0.6), transparent);
      display: flex;
      justify-content: space-between;
      align-items: center;
    ''';

    // Title
    final title = web.document.createElement('h2') as web.HTMLHeadingElement;
    title.textContent = isVideo ? 'Record Video' : 'Take Photo';
    title.style.cssText = '''
      color: white;
      margin: 0;
      font-size: 20px;
      font-weight: 600;
    ''';

    // Cancel button (X)
    _cancelButton =
        web.document.createElement('button') as web.HTMLButtonElement;
    _cancelButton!.innerHTML = '✕'.toJS;
    _cancelButton!.style.cssText = '''
      background: rgba(255, 255, 255, 0.2);
      border: none;
      color: white;
      font-size: 24px;
      width: 40px;
      height: 40px;
      border-radius: 50%;
      cursor: pointer;
      transition: background 0.3s;
    ''';
    _cancelButton!.onmouseenter = ((web.Event e) {
      _cancelButton!.style.background = 'rgba(255, 255, 255, 0.3)';
    }.toJS) as web.EventHandler?;
    _cancelButton!.onmouseleave = ((web.Event e) {
      _cancelButton!.style.background = 'rgba(255, 255, 255, 0.2)';
    }.toJS) as web.EventHandler?;
    _cancelButton!.onclick = ((web.Event e) {
      _cleanup();
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }.toJS) as web.EventHandler?;

    topBar.appendChild(title);
    topBar.appendChild(_cancelButton!);

    // Create recording indicator (for video)
    if (isVideo) {
      _recordingIndicator =
          web.document.createElement('div') as web.HTMLDivElement;
      _recordingIndicator!.style.cssText = '''
        position: absolute;
        top: 80px;
        left: 50%;
        transform: translateX(-50%);
        background: rgba(255, 0, 0, 0.9);
        color: white;
        padding: 8px 16px;
        border-radius: 20px;
        font-weight: bold;
        display: none;
        align-items: center;
        gap: 8px;
      ''';
      _recordingIndicator!.innerHTML = '''
        <span style="width: 8px; height: 8px; background: white; border-radius: 50%; animation: blink 0.8s infinite;"></span>
        <span id="timer">REC 00:00</span>
      '''.toJS;
    }

    // Create bottom controls
    final controls = web.document.createElement('div') as web.HTMLDivElement;
    controls.style.cssText = '''
      position: absolute;
      bottom: 0;
      left: 0;
      right: 0;
      padding: 40px;
      background: linear-gradient(to top, rgba(0,0,0,0.8), transparent);
      display: flex;
      justify-content: center;
      align-items: center;
    ''';

    // Capture/Record button
    _captureButton =
        web.document.createElement('button') as web.HTMLButtonElement;
    _captureButton!.style.cssText = '''
      width: 70px;
      height: 70px;
      border-radius: 50%;
      border: 4px solid white;
      background: ${isVideo ? 'rgba(255, 0, 0, 0.3)' : 'rgba(255, 255, 255, 0.3)'};
      cursor: pointer;
      transition: all 0.3s;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 32px;
    ''';
    _captureButton!.innerHTML = (isVideo ? '●' : '📷').toJS;

    bool isRecording = false;

    _captureButton!.onclick = ((web.Event e) {
      if (isVideo) {
        if (!isRecording) {
          // Start recording
          isRecording = true;
          _captureButton!.innerHTML = '⏹'.toJS;
          _captureButton!.style.background = 'rgba(255, 0, 0, 0.8)';
          _recordingIndicator!.style.display = 'flex';
          _startTimer();
          // Don't complete yet, wait for stop
        } else {
          // Stop recording
          _stopTimer();
          _cleanup();
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        }
      } else {
        // Capture photo
        _cleanup();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    }.toJS) as web.EventHandler?;

    _captureButton!.onmouseenter = ((web.Event e) {
      _captureButton!.style.transform = 'scale(1.1)';
    }.toJS) as web.EventHandler?;
    _captureButton!.onmouseleave = ((web.Event e) {
      _captureButton!.style.transform = 'scale(1.0)';
    }.toJS) as web.EventHandler?;

    controls.appendChild(_captureButton!);

    // Assemble UI
    _container!.appendChild(topBar);
    _container!.appendChild(_video!);
    if (isVideo) {
      _container!.appendChild(_recordingIndicator!);
    }
    _container!.appendChild(controls);

    // Add keyframe animation for blinking dot
    final style = web.document.createElement('style') as web.HTMLStyleElement;
    style.textContent = '''
      @keyframes blink {
        0%, 100% { opacity: 1; }
        50% { opacity: 0; }
      }
    ''';
    _container!.appendChild(style);

    // Add to document
    web.document.body?.appendChild(_container!);

    return completer.future;
  }

  void _startTimer() {
    _elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      final minutes = _elapsedSeconds ~/ 60;
      final seconds = _elapsedSeconds % 60;
      final timerElement = web.document.getElementById('timer');
      if (timerElement != null) {
        timerElement.textContent =
            'REC ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _cleanup() {
    _stopTimer();
    _container?.remove();
    _container = null;
    _video = null;
    _captureButton = null;
    _cancelButton = null;
    _recordingIndicator = null;
  }
}
