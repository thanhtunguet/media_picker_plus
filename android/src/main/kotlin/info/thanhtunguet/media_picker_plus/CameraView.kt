package info.thanhtunguet.media_picker_plus

import android.app.Activity
import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.view.View
import androidx.camera.core.*
import androidx.camera.camera2.interop.Camera2CameraInfo
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.io.File
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class CameraViewFactory(
    private val messenger: BinaryMessenger,
    private val activityProvider: () -> Activity?
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<String, Any>
        return CameraView(context, messenger, activityProvider, creationParams)
    }
}

class CameraView(
    private val context: Context,
    messenger: BinaryMessenger,
    private val activityProvider: () -> Activity?,
    creationParams: Map<String, Any>?
) : PlatformView, MethodChannel.MethodCallHandler {

    private enum class BackLensMode {
        WIDE,
        ULTRA_WIDE,
    }

    private val previewView: PreviewView = PreviewView(context)
    private val cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private var preview: Preview? = null
    private var imageCapture: ImageCapture? = null
    private var camera: Camera? = null
    private var cameraProvider: ProcessCameraProvider? = null
    private var lifecycleOwner: LifecycleOwner? = null
    private var preferredCameraDevice: String = "back"
    private var currentBackLensMode: BackLensMode = BackLensMode.WIDE
    private var ultraWideBackCameraId: String? = null
    private val methodChannel: MethodChannel =
        MethodChannel(messenger, "info.thanhtunguet.media_picker_plus/camera")

    init {
        methodChannel.setMethodCallHandler(this)
        startCamera(creationParams)
    }

    override fun getView(): View {
        return previewView
    }

    override fun dispose() {
        cameraExecutor.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "capturePhoto" -> {
                capturePhoto(result)
            }
            "setZoom" -> {
                val zoom = call.argument<Double>("zoom")
                if (zoom != null) {
                    setZoom(zoom.toFloat())
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "Zoom value required", null)
                }
            }
            "dispose" -> {
                dispose()
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun startCamera(params: Map<String, Any>?) {
        preferredCameraDevice = (params?.get("preferredCameraDevice") as? String) ?: "back"

        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)

        cameraProviderFuture.addListener({
            cameraProvider = cameraProviderFuture.get()

            // Preview
            preview = Preview.Builder()
                .build()
                .also {
                    it.setSurfaceProvider(previewView.surfaceProvider)
                }

            // ImageCapture
            imageCapture = ImageCapture.Builder()
                .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
                .build()

            try {
                // Unbind all use cases before rebinding
                cameraProvider?.unbindAll()

                // Get the activity as LifecycleOwner
                val activity = activityProvider()
                lifecycleOwner = activity as? LifecycleOwner

                ultraWideBackCameraId = if (preferredCameraDevice == "back") {
                    findUltraWideBackCameraId()
                } else {
                    null
                }

                if (lifecycleOwner != null) {
                    bindCameraUseCases(BackLensMode.WIDE)
                } else {
                    android.util.Log.e("CameraView", "Activity is not a LifecycleOwner")
                }
            } catch (exc: Exception) {
                android.util.Log.e("CameraView", "Use case binding failed", exc)
            }

        }, ContextCompat.getMainExecutor(context))
    }

    private fun capturePhoto(result: MethodChannel.Result) {
        val imageCapture = imageCapture ?: run {
            result.error("NO_CAMERA", "Camera not initialized", null)
            return
        }

        // Create temp file
        val photoFile = File(
            context.cacheDir,
            "media_picker_plus_${System.currentTimeMillis()}.jpg"
        )

        val outputOptions = ImageCapture.OutputFileOptions.Builder(photoFile).build()

        imageCapture.takePicture(
            outputOptions,
            ContextCompat.getMainExecutor(context),
            object : ImageCapture.OnImageSavedCallback {
                override fun onError(exc: ImageCaptureException) {
                    result.error("CAPTURE_ERROR", "Failed to capture photo: ${exc.message}", null)
                }

                override fun onImageSaved(output: ImageCapture.OutputFileResults) {
                    result.success(photoFile.absolutePath)
                }
            }
        )
    }

    private fun setZoom(ratio: Float) {
        val targetRatio = switchBackLensIfNeeded(ratio)
        val zoomState = camera?.cameraInfo?.zoomState?.value
        val clampedRatio = if (zoomState != null) {
            targetRatio.coerceIn(zoomState.minZoomRatio, zoomState.maxZoomRatio)
        } else {
            targetRatio
        }

        camera?.cameraControl?.setZoomRatio(clampedRatio)
    }

    private fun switchBackLensIfNeeded(requestedRatio: Float): Float {
        if (preferredCameraDevice != "back") {
            return requestedRatio
        }

        if (requestedRatio < 1f) {
            if (currentBackLensMode != BackLensMode.ULTRA_WIDE && ultraWideBackCameraId != null) {
                bindCameraUseCases(BackLensMode.ULTRA_WIDE)
            }

            // Use the ultrawide sensor at its natural 1x zoom.
            return 1f
        }

        if (currentBackLensMode == BackLensMode.ULTRA_WIDE) {
            bindCameraUseCases(BackLensMode.WIDE)
        }

        return requestedRatio
    }

    private fun bindCameraUseCases(backLensMode: BackLensMode) {
        val cameraProvider = cameraProvider ?: return
        val lifecycleOwner = lifecycleOwner ?: return
        val preview = preview ?: return
        val imageCapture = imageCapture ?: return

        val cameraSelector = when (preferredCameraDevice) {
            "front" -> CameraSelector.DEFAULT_FRONT_CAMERA
            else -> buildBackCameraSelector(backLensMode)
        }

        try {
            cameraProvider.unbindAll()
            camera = cameraProvider.bindToLifecycle(
                lifecycleOwner,
                cameraSelector,
                preview,
                imageCapture
            )
            if (preferredCameraDevice == "back") {
                currentBackLensMode = backLensMode
            }
        } catch (exc: Exception) {
            android.util.Log.e("CameraView", "Use case binding failed", exc)

            if (preferredCameraDevice == "back" && backLensMode == BackLensMode.ULTRA_WIDE) {
                // Fall back to the default back camera when ultrawide binding fails.
                bindCameraUseCases(BackLensMode.WIDE)
            }
        }
    }

    private fun buildBackCameraSelector(backLensMode: BackLensMode): CameraSelector {
        if (backLensMode == BackLensMode.ULTRA_WIDE) {
            val cameraId = ultraWideBackCameraId
            if (cameraId != null) {
                return CameraSelector.Builder()
                    .requireLensFacing(CameraSelector.LENS_FACING_BACK)
                    .addCameraFilter { infos ->
                        infos.filter { info ->
                            runCatching {
                                Camera2CameraInfo.from(info).cameraId == cameraId
                            }.getOrDefault(false)
                        }
                    }
                    .build()
            }
        }

        return CameraSelector.DEFAULT_BACK_CAMERA
    }

    private fun findUltraWideBackCameraId(): String? {
        val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as? CameraManager
            ?: return null

        val focalById = mutableListOf<Pair<String, Float>>()
        for (cameraId in cameraManager.cameraIdList) {
            val characteristics = runCatching {
                cameraManager.getCameraCharacteristics(cameraId)
            }.getOrNull() ?: continue

            val lensFacing = characteristics.get(CameraCharacteristics.LENS_FACING)
            if (lensFacing != CameraCharacteristics.LENS_FACING_BACK) continue

            val focalLengths = characteristics
                .get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)
                ?.filter { it > 0f }
                ?: continue

            val minFocal = focalLengths.minOrNull() ?: continue
            focalById.add(cameraId to minFocal)
        }

        if (focalById.size < 2) return null

        val sortedByFocal = focalById.sortedBy { it.second }
        val ultraWideCandidate = sortedByFocal[0]
        val wideCandidate = sortedByFocal[1]

        // Require a meaningful focal-length gap to avoid selecting the same lens type.
        return if (ultraWideCandidate.second < wideCandidate.second * 0.9f) {
            ultraWideCandidate.first
        } else {
            null
        }
    }
}
