package info.thanhtunguet.media_picker_plus

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Typeface
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.result.contract.ActivityResultContracts.PickVisualMedia
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import android.media.MediaMetadataRetriever
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import com.arthenica.ffmpegkit.FFmpegKit
import com.arthenica.ffmpegkit.ReturnCode
import com.arthenica.ffmpegkit.Session
import com.arthenica.ffmpegkit.LogCallback
import com.arthenica.ffmpegkit.StatisticsCallback
import java.io.File
import java.io.FileOutputStream
import android.os.Handler
import android.os.Looper
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min

class MediaPickerPlusPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener, PluginRegistry.RequestPermissionsResultListener {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var pendingResult: Result? = null
    private var currentMediaPath: String? = null
    @Volatile
    private var mediaOptions: HashMap<String, Any>? = null
    private var currentMediaAction: (() -> Unit)? = null
    private var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding? = null

    // Request codes
    private val REQUEST_IMAGE_CAPTURE = 1001
    private val REQUEST_VIDEO_CAPTURE = 1002
    private val REQUEST_PICK_IMAGE = 1003
    private val REQUEST_PICK_VIDEO = 1004
    private val REQUEST_PICK_FILE = 1005
    private val REQUEST_PICK_MULTIPLE_FILES = 1006
    private val REQUEST_PICK_MULTIPLE_MEDIA = 1007
    private val REQUEST_CAMERA_PERMISSION = 2001
    private val REQUEST_GALLERY_PERMISSION = 2002
    private val REQUEST_MICROPHONE_PERMISSION = 2003
    
    // Modern Photo Picker (Android 13+)
    private val REQUEST_PHOTO_PICKER = 3001

    // Watermark positions enum
    enum class WatermarkPosition {
        TOP_LEFT, TOP_CENTER, TOP_RIGHT,
        MIDDLE_LEFT, CENTER, MIDDLE_RIGHT,
        BOTTOM_LEFT, BOTTOM_CENTER, BOTTOM_RIGHT;

        companion object {
            fun fromString(position: String): WatermarkPosition {
                return when (position.lowercase()) {
                    "topleft" -> TOP_LEFT
                    "topcenter" -> TOP_CENTER
                    "topright" -> TOP_RIGHT
                    "middleleft" -> MIDDLE_LEFT
                    "center" -> CENTER
                    "middleright" -> MIDDLE_RIGHT
                    "bottomleft" -> BOTTOM_LEFT
                    "bottomcenter" -> BOTTOM_CENTER
                    else -> BOTTOM_RIGHT // Default
                }
            }
        }
    }

    companion object {
        private val timestampFormatter = SimpleDateFormat("yyyyMMdd_HHmmss_SSS", Locale.US)

        /**
         * Generates a unique timestamp string with millisecond precision.
         * Format: yyyyMMdd_HHmmss_SSS (e.g., 20240115_143052_123)
         */
        fun generateTimestamp(): String {
            return timestampFormatter.format(Date())
        }
    }

    /**
     * Calculate watermark font size from options.
     * If watermarkFontSizePercentage is provided, calculates based on shorter edge.
     * Otherwise, uses watermarkFontSize or default value.
     */
    private fun calculateWatermarkFontSize(
        options: HashMap<String, Any>?,
        width: Int,
        height: Int,
        defaultSize: Float = 30f
    ): Float {
        if (options == null) return defaultSize

        // Check if percentage is provided
        val percentage = options["watermarkFontSizePercentage"] as? Double
        if (percentage != null) {
            val shorterEdge = min(width, height).toFloat()
            return shorterEdge * (percentage.toFloat() / 100f)
        }

        // Fall back to absolute font size
        return (options["watermarkFontSize"] as? Double)?.toFloat() ?: defaultSize
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        this.flutterPluginBinding = flutterPluginBinding
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "info.thanhtunguet.media_picker_plus"
        )
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext

        // Register camera view factory with activity provider
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "info.thanhtunguet.media_picker_plus/camera_view",
            CameraViewFactory(flutterPluginBinding.binaryMessenger) { activity }
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        Log.d("MediaPickerPlus", "onMethodCall: ${call.method}")
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${Build.VERSION.RELEASE}")
            }

            "pickMedia" -> {
                val source = call.argument<String>("source")
                val type = call.argument<String>("type")
                mediaOptions = call.argument<HashMap<String, Any>>("options")
                
                Log.d("MediaPickerPlus", "pickMedia - source: $source, type: $type")
                Log.d("MediaPickerPlus", "pickMedia - mediaOptions: $mediaOptions")

                pendingResult = result

                when (source) {
                    "gallery" -> {
                        if (hasGalleryPermissionForType(type)) {
                            when (type) {
                                "image" -> pickImageFromGallery()
                                "video" -> pickVideoFromGallery()
                                else -> result.error(
                                    "INVALID_TYPE",
                                    "Invalid media type specified",
                                    null
                                )
                            }
                        } else {
                            // Store the action to execute after permission is granted
                            currentMediaAction = when (type) {
                                "image" -> ({ pickImageFromGallery() })
                                "video" -> ({ pickVideoFromGallery() })
                                else -> null
                            }
                            if (currentMediaAction != null) {
                                requestGalleryPermissionForType(type)
                            } else {
                                result.error("INVALID_TYPE", "Invalid media type specified", null)
                            }
                        }
                    }

                    "camera" -> {
                        if (hasCameraPermission()) {
                            when (type) {
                                "image" -> capturePhoto()
                                "video" -> recordVideoWithPermissions()
                                else -> result.error(
                                    "INVALID_TYPE",
                                    "Invalid media type specified",
                                    null
                                )
                            }
                        } else {
                            // Store the action to execute after permission is granted
                            currentMediaAction = when (type) {
                                "image" -> ({ capturePhoto() })
                                "video" -> ({ recordVideoWithPermissions() })
                                else -> null
                            }
                            if (currentMediaAction != null) {
                                requestCameraPermission()
                            } else {
                                result.error("INVALID_TYPE", "Invalid media type specified", null)
                            }
                        }
                    }

                    else -> result.error("INVALID_SOURCE", "Invalid media source specified", null)
                }
            }

            "hasCameraPermission" -> {
                result.success(hasCameraPermission())
            }

            "requestCameraPermission" -> {
                pendingResult = result
                requestCameraPermission()
            }

            "hasGalleryPermission" -> {
                result.success(hasGalleryPermission())
            }

            "requestGalleryPermission" -> {
                pendingResult = result
                requestGalleryPermission()
            }

            "pickFile" -> {
                val allowedExtensions = call.argument<List<String>>("allowedExtensions")
                mediaOptions = call.argument<HashMap<String, Any>>("options")
                pendingResult = result
                pickFile(allowedExtensions)
            }

            "pickMultipleFiles" -> {
                val allowedExtensions = call.argument<List<String>>("allowedExtensions")
                mediaOptions = call.argument<HashMap<String, Any>>("options")
                pendingResult = result
                pickMultipleFiles(allowedExtensions)
            }

            "pickMultipleMedia" -> {
                val source = call.argument<String>("source")
                val type = call.argument<String>("type")
                mediaOptions = call.argument<HashMap<String, Any>>("options")
                pendingResult = result
                if (source == "gallery") {
                    if (hasGalleryPermissionForType(type)) {
                        pickMultipleMedia(source, type)
                    } else {
                        currentMediaAction = ({ pickMultipleMedia(source, type) })
                        requestGalleryPermissionForType(type)
                    }
                } else {
                    pickMultipleMedia(source, type)
                }
            }

            "processImage" -> {
                val imagePath = call.argument<String>("imagePath")
                val options = call.argument<HashMap<String, Any>>("options")
                
                if (imagePath == null) {
                    result.error("INVALID_ARGUMENTS", "Image path is required", null)
                    return
                }
                
                processImage(imagePath, options ?: HashMap(), result)
            }
            
            "addWatermarkToImage" -> {
                val imagePath = call.argument<String>("imagePath")
                val options = call.argument<HashMap<String, Any>>("options")
                
                if (imagePath == null) {
                    result.error("INVALID_ARGUMENTS", "Image path is required", null)
                    return
                }
                
                addWatermarkToExistingImage(imagePath, options ?: HashMap(), result)
            }
            
            "addWatermarkToVideo" -> {
                val videoPath = call.argument<String>("videoPath")
                val options = call.argument<HashMap<String, Any>>("options")
                
                if (videoPath == null) {
                    result.error("INVALID_ARGUMENTS", "Video path is required", null)
                    return
                }
                
                addWatermarkToExistingVideo(videoPath, options ?: HashMap(), result)
            }
            
            "getThumbnail" -> {
                val videoPath = call.argument<String>("videoPath")
                val timeInSeconds = call.argument<Double>("timeInSeconds") ?: 1.0
                val options = call.argument<HashMap<String, Any>>("options")
                
                if (videoPath == null) {
                    result.error("INVALID_ARGUMENTS", "Video path is required", null)
                    return
                }
                
                extractThumbnail(videoPath, timeInSeconds, options, result)
            }
            
            "compressVideo" -> {
                val inputPath = call.argument<String>("inputPath")
                val outputPath = call.argument<String>("outputPath")
                val options = call.argument<HashMap<String, Any>>("options")
                
                if (inputPath == null) {
                    result.error("INVALID_ARGUMENTS", "Input path is required", null)
                    return
                }
                
                compressVideo(inputPath, outputPath, options ?: HashMap(), result)
            }
            
            "applyImage" -> {
                val imagePath = call.argument<String>("imagePath")
                val options = call.argument<HashMap<String, Any>>("options")
                
                if (imagePath == null) {
                    result.error("INVALID_ARGUMENTS", "Image path is required", null)
                    return
                }
                
                processImage(imagePath, options ?: HashMap(), result)
            }
            
            "applyVideo" -> {
                val videoPath = call.argument<String>("videoPath")
                val options = call.argument<HashMap<String, Any>>("options")
                
                if (videoPath == null) {
                    result.error("INVALID_ARGUMENTS", "Video path is required", null)
                    return
                }
                
                applyVideo(videoPath, options ?: HashMap(), result)
            }

            else -> result.notImplemented()
        }
    }

    private fun createMediaFile(isImage: Boolean): File? {
        try {
            val timeStamp = generateTimestamp()
            val fileName = if (isImage) "IMG_${timeStamp}" else "VID_${timeStamp}"
            val extension = if (isImage) ".jpg" else ".mp4"
            
            // Use app-specific storage for better compatibility across API levels
            val storageDir = when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> {
                    // Android 10+ (API 29+): Use app-specific directory to avoid scoped storage issues
                    context.getExternalFilesDir(Environment.DIRECTORY_PICTURES)
                }
                else -> {
                    // Android 9 and below: Use external files directory
                    context.getExternalFilesDir(Environment.DIRECTORY_PICTURES)
                }
            }
            
            val file = File.createTempFile(fileName, extension, storageDir)
            currentMediaPath = file.absolutePath
            return file
        } catch (e: IOException) {
            e.printStackTrace()
        }
        return null
    }

    private fun applyPreferredCameraDevice(intent: Intent) {
        val preferred = (mediaOptions?.get("preferredCameraDevice") as? String)
            ?.lowercase(Locale.US) ?: "auto"

        when (preferred) {
            "front" -> {
                // Best-effort hints; camera apps may ignore these extras.
                intent.putExtra("android.intent.extras.CAMERA_FACING", 1)
                intent.putExtra("android.intent.extras.LENS_FACING_FRONT", 1)
                intent.putExtra("android.intent.extra.USE_FRONT_CAMERA", true)
            }
            "back" -> {
                intent.putExtra("android.intent.extras.CAMERA_FACING", 0)
                intent.putExtra("android.intent.extras.LENS_FACING_BACK", 0)
                intent.putExtra("android.intent.extra.USE_FRONT_CAMERA", false)
            }
            else -> {
                // auto: do nothing
            }
        }
    }

    private fun capturePhoto() {
        val activity = activity ?: return

        Intent(MediaStore.ACTION_IMAGE_CAPTURE).also { intent ->
            intent.resolveActivity(activity.packageManager)?.also {
                applyPreferredCameraDevice(intent)
                val photoFile = createMediaFile(true)
                photoFile?.also {
                    val photoURI = FileProvider.getUriForFile(
                        context,
                        context.packageName + ".fileprovider",
                        it
                    )
                    intent.putExtra(MediaStore.EXTRA_OUTPUT, photoURI)
                    activity.startActivityForResult(intent, REQUEST_IMAGE_CAPTURE)
                }
            }
        }
    }

    private fun recordVideoWithPermissions() {
        if (hasMicrophonePermission()) {
            recordVideo()
        } else {
            requestMicrophonePermission()
        }
    }

    private fun recordVideo() {
        val activity = activity ?: return

        Intent(MediaStore.ACTION_VIDEO_CAPTURE).also { intent ->
            intent.resolveActivity(activity.packageManager)?.also {
                applyPreferredCameraDevice(intent)

                val maxDurationSeconds = (mediaOptions?.get("maxDuration") as? Number)?.toInt()
                if (maxDurationSeconds != null && maxDurationSeconds > 0) {
                    intent.putExtra(MediaStore.EXTRA_DURATION_LIMIT, maxDurationSeconds)
                }

                val videoFile = createMediaFile(false)
                videoFile?.also {
                    val videoURI = FileProvider.getUriForFile(
                        context,
                        context.packageName + ".fileprovider",
                        it
                    )
                    intent.putExtra(MediaStore.EXTRA_OUTPUT, videoURI)
                    activity.startActivityForResult(intent, REQUEST_VIDEO_CAPTURE)
                }
            }
        }
    }

    private fun pickImageFromGallery() {
        val activity = activity ?: return

        // Use modern Photo Picker API for Android 13+ when available
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && isPhotoPickerAvailable()) {
            val intent = Intent(MediaStore.ACTION_PICK_IMAGES)
            intent.putExtra(MediaStore.EXTRA_PICK_IMAGES_MAX, 1)
            activity.startActivityForResult(intent, REQUEST_PHOTO_PICKER)
        } else {
            // Fallback to traditional gallery picker
            val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
            activity.startActivityForResult(intent, REQUEST_PICK_IMAGE)
        }
    }

    private fun pickVideoFromGallery() {
        val activity = activity ?: return

        // Use modern Photo Picker API for Android 13+ when available
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && isPhotoPickerAvailable()) {
            val intent = Intent(MediaStore.ACTION_PICK_IMAGES)
            intent.putExtra(MediaStore.EXTRA_PICK_IMAGES_MAX, 1)
            // Note: As of Android 13, the photo picker doesn't support video selection
            // We'll use the traditional method for videos
            val videoIntent = Intent(Intent.ACTION_PICK, MediaStore.Video.Media.EXTERNAL_CONTENT_URI)
            activity.startActivityForResult(videoIntent, REQUEST_PICK_VIDEO)
        } else {
            // Fallback to traditional gallery picker
            val intent = Intent(Intent.ACTION_PICK, MediaStore.Video.Media.EXTERNAL_CONTENT_URI)
            activity.startActivityForResult(intent, REQUEST_PICK_VIDEO)
        }
    }

    private fun hasCameraPermission(): Boolean {
        return when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                // Android 6.0+ (API 23+): Runtime permission required
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.CAMERA
                ) == PackageManager.PERMISSION_GRANTED
            }
            else -> {
                // Android 5.1 and below (API 22 and below): Permissions granted at install time
                true
            }
        }
    }

    private fun requestCameraPermission() {
        activity?.let {
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                    // Android 6.0+ (API 23+): Request runtime permission
                    ActivityCompat.requestPermissions(
                        it,
                        arrayOf(Manifest.permission.CAMERA),
                        REQUEST_CAMERA_PERMISSION
                    )
                }
                else -> {
                    // Android 5.1 and below (API 22 and below): No runtime permissions needed
                    pendingResult?.success(true)
                }
            }
        }
    }

    private fun hasMicrophonePermission(): Boolean {
        return when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                // Android 6.0+ (API 23+): Runtime permission required
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.RECORD_AUDIO
                ) == PackageManager.PERMISSION_GRANTED
            }
            else -> {
                // Android 5.1 and below (API 22 and below): Permissions granted at install time
                true
            }
        }
    }

    private fun requestMicrophonePermission() {
        activity?.let {
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                    // Android 6.0+ (API 23+): Request runtime permission
                    ActivityCompat.requestPermissions(
                        it,
                        arrayOf(Manifest.permission.RECORD_AUDIO),
                        REQUEST_MICROPHONE_PERMISSION
                    )
                }
                else -> {
                    // Android 5.1 and below (API 22 and below): No runtime permissions needed
                    pendingResult?.success(true)
                }
            }
        }
    }

    private fun hasGalleryPermission(): Boolean {
        return when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU -> {
                // Android 13+ (API 33+): Use granular media permissions
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.READ_MEDIA_IMAGES
                ) == PackageManager.PERMISSION_GRANTED &&
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.READ_MEDIA_VIDEO
                ) == PackageManager.PERMISSION_GRANTED
            }
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                // Android 6.0+ (API 23+): Use READ_EXTERNAL_STORAGE
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.READ_EXTERNAL_STORAGE
                ) == PackageManager.PERMISSION_GRANTED
            }
            else -> {
                // Android 5.1 and below (API 22 and below): Permissions granted at install time
                true
            }
        }
    }

    private fun hasGalleryPermissionForType(type: String?): Boolean {
        return when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU -> {
                when (type) {
                    "image" -> ContextCompat.checkSelfPermission(
                        context,
                        Manifest.permission.READ_MEDIA_IMAGES
                    ) == PackageManager.PERMISSION_GRANTED
                    "video" -> ContextCompat.checkSelfPermission(
                        context,
                        Manifest.permission.READ_MEDIA_VIDEO
                    ) == PackageManager.PERMISSION_GRANTED
                    else -> hasGalleryPermission()
                }
            }
            else -> hasGalleryPermission()
        }
    }

    private fun requestGalleryPermission() {
        activity?.let {
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU -> {
                    // Android 13+ (API 33+): Request granular media permissions
                    ActivityCompat.requestPermissions(
                        it,
                        arrayOf(
                            Manifest.permission.READ_MEDIA_IMAGES,
                            Manifest.permission.READ_MEDIA_VIDEO
                        ),
                        REQUEST_GALLERY_PERMISSION
                    )
                }
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                    // Android 6.0+ (API 23+): Request READ_EXTERNAL_STORAGE
                    ActivityCompat.requestPermissions(
                        it,
                        arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE),
                        REQUEST_GALLERY_PERMISSION
                    )
                }
                else -> {
                    // Android 5.1 and below (API 22 and below): No runtime permissions needed
                    pendingResult?.success(true)
                }
            }
        }
    }

    private fun requestGalleryPermissionForType(type: String?) {
        activity?.let {
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU -> {
                    val permissions = when (type) {
                        "image" -> arrayOf(Manifest.permission.READ_MEDIA_IMAGES)
                        "video" -> arrayOf(Manifest.permission.READ_MEDIA_VIDEO)
                        else -> arrayOf(
                            Manifest.permission.READ_MEDIA_IMAGES,
                            Manifest.permission.READ_MEDIA_VIDEO
                        )
                    }
                    ActivityCompat.requestPermissions(
                        it,
                        permissions,
                        REQUEST_GALLERY_PERMISSION
                    )
                }
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                    ActivityCompat.requestPermissions(
                        it,
                        arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE),
                        REQUEST_GALLERY_PERMISSION
                    )
                }
                else -> {
                    pendingResult?.success(true)
                }
            }
        }
    }

    private fun getFilePathFromUri(uri: Uri): String? {
        Log.d("MediaPickerPlus", "getFilePathFromUri: URI = $uri, scheme = ${uri.scheme}")
        
        return when (uri.scheme) {
            "file" -> {
                // Direct file path
                val path = uri.path
                Log.d("MediaPickerPlus", "File scheme, path: $path")
                path
            }
            "content" -> {
                // Content URI - handle different providers
                when {
                    // Android 10+ (API 29+) - Always use stream copying for content URIs
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> {
                        Log.d("MediaPickerPlus", "Android 10+, using stream copying for content URI")
                        copyUriToTempFile(uri)
                    }
                    // Android 9 and below - Try DATA column first, then fallback to copying
                    else -> {
                        Log.d("MediaPickerPlus", "Android 9 and below, trying DATA column first")
                        tryGetPathFromDataColumn(uri) ?: copyUriToTempFile(uri)
                    }
                }
            }
            else -> {
                Log.d("MediaPickerPlus", "Unknown scheme, attempting to copy URI to temp file")
                copyUriToTempFile(uri)
            }
        }
    }
    
    private fun tryGetPathFromDataColumn(uri: Uri): String? {
        return try {
            val projection = arrayOf(MediaStore.MediaColumns.DATA)
            val cursor = context.contentResolver.query(uri, projection, null, null, null)
            cursor?.use {
                if (it.moveToFirst()) {
                    val columnIndex = it.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)
                    val path = it.getString(columnIndex)
                    Log.d("MediaPickerPlus", "Got path from DATA column: $path")
                    // Verify the file actually exists
                    if (path != null && File(path).exists()) {
                        return path
                    }
                }
            }
            null
        } catch (e: Exception) {
            Log.e("MediaPickerPlus", "Error getting path from DATA column: ${e.message}")
            null
        }
    }

    private fun copyUriToTempFile(uri: Uri): String? {
        return try {
            Log.d("MediaPickerPlus", "copyUriToTempFile: Starting copy for URI = $uri")
            
            val timeStamp = generateTimestamp()
            val storageDir = context.getExternalFilesDir(Environment.DIRECTORY_PICTURES)

            if (storageDir == null) {
                Log.e("MediaPickerPlus", "Failed to get external files directory")
                return null
            }
            
            // Ensure directory exists
            if (!storageDir.exists() && !storageDir.mkdirs()) {
                Log.e("MediaPickerPlus", "Failed to create storage directory: ${storageDir.absolutePath}")
                return null
            }
            
            val mimeType = context.contentResolver.getType(uri)
            Log.d("MediaPickerPlus", "MIME type: $mimeType")
            
            val extension = when {
                mimeType?.contains("image") == true -> ".jpg"
                mimeType?.contains("video") == true -> ".mp4"
                mimeType?.startsWith("application/pdf") == true -> ".pdf"
                mimeType?.startsWith("text/") == true -> ".txt"
                else -> {
                    // Try to get extension from URI path
                    val lastSegment = uri.lastPathSegment
                    if (lastSegment?.contains(".") == true) {
                        val ext = lastSegment.substringAfterLast(".")
                        if (ext.isNotEmpty()) ".$ext" else ".tmp"
                    } else ".tmp"
                }
            }
            
            val file = File.createTempFile("MEDIA_${timeStamp}", extension, storageDir)
            Log.d("MediaPickerPlus", "Created temp file: ${file.absolutePath}")
            
            val inputStream = context.contentResolver.openInputStream(uri)
            if (inputStream == null) {
                Log.e("MediaPickerPlus", "Failed to open input stream for URI: $uri")
                return null
            }
            
            inputStream.use { input ->
                FileOutputStream(file).use { output ->
                    val bytesCount = input.copyTo(output)
                    Log.d("MediaPickerPlus", "Copied $bytesCount bytes to temp file")
                }
            }
            
            if (!file.exists() || file.length() == 0L) {
                Log.e("MediaPickerPlus", "Temp file was not created properly or is empty")
                return null
            }
            
            Log.d("MediaPickerPlus", "Successfully copied URI to temp file: ${file.absolutePath}, size: ${file.length()} bytes")
            return file.absolutePath
        } catch (e: SecurityException) {
            Log.e("MediaPickerPlus", "Security exception copying URI to temp file: ${e.message}")
            null
        } catch (e: Exception) {
            Log.e("MediaPickerPlus", "Error copying URI to temp file: ${e.message}", e)
            null
        }
    }

    /**
     * Process image using the global mediaOptions.
     * Delegates to processImageWithOptions for the actual processing.
     */
    private fun processImage(sourcePath: String): String {
        val options = mediaOptions ?: return sourcePath
        return processImageWithOptions(sourcePath, options)
    }
    
    /**
     * Process image with explicitly provided options.
     * This is thread-safe as it doesn't rely on global mutable state.
     */
    private fun processImageWithOptions(sourcePath: String, options: HashMap<String, Any>): String {
        try {
            var bitmap = android.graphics.BitmapFactory.decodeFile(sourcePath)
            
            // Apply cropping if specified
            if (options.containsKey("cropOptions")) {
                val cropOptionsMap = options["cropOptions"] as? HashMap<String, Any>
                if (cropOptionsMap != null && cropOptionsMap["enableCrop"] == true) {
                    bitmap = applyCropToBitmap(bitmap, cropOptionsMap)
                }
            }
            
            if (options.containsKey("maxWidth") && options.containsKey("maxHeight")) {
                val maxWidth = options["maxWidth"] as? Int ?: 0
                val maxHeight = options["maxHeight"] as? Int ?: 0
                if (maxWidth > 0 && maxHeight > 0) {
                    val width = bitmap.width
                    val height = bitmap.height
                    val widthRatio = maxWidth.toFloat() / width
                    val heightRatio = maxHeight.toFloat() / height
                    val ratio = min(widthRatio, heightRatio)
                    if (ratio < 1) {
                        val newWidth = (width * ratio).toInt()
                        val newHeight = (height * ratio).toInt()
                        bitmap = Bitmap.createScaledBitmap(bitmap, newWidth, newHeight, true)
                    }
                }
            }
            if (options.containsKey("watermark")) {
                val watermarkText = options["watermark"] as? String
                if (!watermarkText.isNullOrEmpty()) {
                    val fontSize = calculateWatermarkFontSize(options, bitmap.width, bitmap.height, 24f)
                    val positionObj = options["watermarkPosition"]
                    val position = if (positionObj is String) {
                        positionObj
                    } else {
                        "bottomRight"
                    }
                    bitmap = addWatermarkToBitmap(bitmap, watermarkText, fontSize, position)
                }
            }
            var quality = 85
            if (options.containsKey("imageQuality")) {
                val imageQuality = when (val imageQualityValue = options["imageQuality"]) {
                    is Int -> imageQualityValue
                    is Double -> imageQualityValue.toInt()
                    is Boolean -> if (imageQualityValue) 90 else 75
                    else -> 85
                }
                quality = when {
                    imageQuality >= 90 -> 90
                    imageQuality >= 80 -> 85
                    else -> 75
                }
            }
            val timeStamp = generateTimestamp()
            val fileName = "IMG_PROCESSED_$timeStamp.jpg"
            val storageDir = context.getExternalFilesDir(Environment.DIRECTORY_PICTURES)
            val outputFile = File(storageDir, fileName)
            FileOutputStream(outputFile).use { out ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, quality, out)
            }
            val sourceFile = File(sourcePath)
            if (sourceFile.name.contains("IMG_") && sourceFile.parentFile == storageDir) {
                sourceFile.delete()
            }
            return outputFile.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            return sourcePath
        }
    }

    private fun addWatermarkToBitmap(
        bitmap: Bitmap,
        text: String,
        fontSize: Float,
        positionStr: String
    ): Bitmap {
        val result = bitmap.copy(Bitmap.Config.ARGB_8888, true)
        val canvas = Canvas(result)
        val textPaint = TextPaint().apply {
            color = Color.WHITE
            alpha = 200
            textSize = fontSize
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            isAntiAlias = true
        }
        val strokePaint = TextPaint(textPaint).apply {
            style = Paint.Style.STROKE
            strokeWidth = 2f
            color = Color.BLACK
        }
        val maxLineWidth = calculateMaxLineWidth(text, textPaint)
        val layoutWidth = max(1, ceil(maxLineWidth).toInt())
        val fillLayout = StaticLayout.Builder.obtain(text, 0, text.length, textPaint, layoutWidth)
            .setAlignment(Layout.Alignment.ALIGN_CENTER)
            .setIncludePad(false)
            .build()
        val strokeLayout = StaticLayout.Builder.obtain(text, 0, text.length, strokePaint, layoutWidth)
            .setAlignment(Layout.Alignment.ALIGN_CENTER)
            .setIncludePad(false)
            .build()
        val textWidth = fillLayout.width.toFloat()
        val textHeight = fillLayout.height.toFloat()
        val strokeOutset = strokePaint.strokeWidth
        val measuredWidth = textWidth + strokeOutset * 2
        val measuredHeight = textHeight + strokeOutset * 2

        // Calculate 2% padding based on shorter edge for consistent positioning
        val shorterEdge = minOf(bitmap.width, bitmap.height)
        val edgePadding = shorterEdge * 0.02f // 2% of shorter edge

        val position = if (positionStr == "auto") {
            if (bitmap.width > bitmap.height) {
                WatermarkPosition.BOTTOM_RIGHT
            } else {
                WatermarkPosition.BOTTOM_CENTER
            }
        } else {
            WatermarkPosition.fromString(positionStr)
        }
        val x: Float
        val y: Float
        when (position) {
            WatermarkPosition.TOP_LEFT -> {
                x = edgePadding
                y = edgePadding
            }
            WatermarkPosition.TOP_CENTER -> {
                x = (bitmap.width - measuredWidth) / 2f
                y = edgePadding
            }
            WatermarkPosition.TOP_RIGHT -> {
                x = bitmap.width - measuredWidth - edgePadding
                y = edgePadding
            }
            WatermarkPosition.MIDDLE_LEFT -> {
                x = edgePadding
                y = (bitmap.height - measuredHeight) / 2f
            }
            WatermarkPosition.CENTER -> {
                x = (bitmap.width - measuredWidth) / 2f
                y = (bitmap.height - measuredHeight) / 2f
            }
            WatermarkPosition.MIDDLE_RIGHT -> {
                x = bitmap.width - measuredWidth - edgePadding
                y = (bitmap.height - measuredHeight) / 2f
            }
            WatermarkPosition.BOTTOM_LEFT -> {
                x = edgePadding
                y = bitmap.height - measuredHeight - edgePadding
            }
            WatermarkPosition.BOTTOM_CENTER -> {
                x = (bitmap.width - measuredWidth) / 2f
                y = bitmap.height - measuredHeight - edgePadding
            }
            WatermarkPosition.BOTTOM_RIGHT -> {
                x = bitmap.width - measuredWidth - edgePadding
                y = bitmap.height - measuredHeight - edgePadding
            }
        }
        val maxX = max(edgePadding, bitmap.width - measuredWidth - edgePadding)
        val maxY = max(edgePadding, bitmap.height - measuredHeight - edgePadding)
        val clampedX = x.coerceIn(edgePadding, maxX)
        val clampedY = y.coerceIn(edgePadding, maxY)

        canvas.save()
        canvas.translate(clampedX + strokeOutset, clampedY + strokeOutset)
        strokeLayout.draw(canvas)
        fillLayout.draw(canvas)
        canvas.restore()
        return result
    }

    private fun calculateMaxLineWidth(text: String, paint: TextPaint): Float {
        var maxWidth = 0f
        text.split('\n').forEach { line ->
            val lineWidth = paint.measureText(line)
            if (lineWidth > maxWidth) {
                maxWidth = lineWidth
            }
        }
        return maxWidth
    }

    /**
     * Process video using the global mediaOptions.
     * Delegates to processVideoWithOptions for the actual processing.
     */
    private fun processVideo(sourcePath: String): String {
        val options = mediaOptions ?: return sourcePath
        return processVideoWithOptions(sourcePath, options)
    }
    
    /**
     * Process video with explicitly provided options.
     * This is thread-safe as it doesn't rely on global mutable state.
     */
    private fun processVideoWithOptions(sourcePath: String, options: HashMap<String, Any>): String {
        Log.d("MediaPickerPlus", "processVideoWithOptions called with sourcePath: $sourcePath")
        Log.d("MediaPickerPlus", "options: $options")
        
        if (!options.containsKey("watermark")) {
            Log.d("MediaPickerPlus", "No watermark option found, returning original path")
            return sourcePath
        }
        
        val watermarkText = options["watermark"] as? String
        Log.d("MediaPickerPlus", "Watermark text: $watermarkText")
        
        if (watermarkText.isNullOrEmpty()) {
            Log.d("MediaPickerPlus", "Watermark text is null or empty, returning original path")
            return sourcePath
        }
        try {
            val timeStamp = generateTimestamp()
            val videoFileName = "VID_PROCESSED_$timeStamp.mp4"
            val storageDir = context.getExternalFilesDir(Environment.DIRECTORY_PICTURES)
            val outputVideoFile = File(storageDir, videoFileName)
            
            // Get video dimensions and rotation to calculate font size
            val retriever = MediaMetadataRetriever()
            var videoWidth = 1920  // Default fallback
            var videoHeight = 1080 // Default fallback
            var rotation = 0
            try {
                retriever.setDataSource(sourcePath)
                videoWidth = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toInt() ?: 1920
                videoHeight = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toInt() ?: 1080
                rotation = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toInt() ?: 0
                
                // For rotated videos, use effective (post-rotation) dimensions for font size calculation
                if (rotation == 90 || rotation == 270) {
                    val temp = videoWidth
                    videoWidth = videoHeight
                    videoHeight = temp
                }
            } finally {
                retriever.release()
            }
            
            val fontSize = calculateWatermarkFontSize(options, videoWidth, videoHeight, 48f)
            val positionObj = options["watermarkPosition"]
            val position = if (positionObj is String) positionObj else "bottomRight"
            val watermarkBitmap = createWatermarkBitmap(watermarkText, fontSize)
            Log.d("MediaPickerPlus", "Created watermark bitmap: ${watermarkBitmap.width}x${watermarkBitmap.height}")
            Log.d("MediaPickerPlus", "Source path: $sourcePath")
            Log.d("MediaPickerPlus", "Output path: ${outputVideoFile.absolutePath}")
            
            val success = watermarkVideoWithNativeProcessing(
                sourcePath,
                outputVideoFile.absolutePath,
                watermarkBitmap,
                position,
                options
            )
            Log.d("MediaPickerPlus", "Watermarking success: $success")
            
            // For debugging: Always return the processed path if processing was attempted
            if (success) {
                Log.d("MediaPickerPlus", "Returning processed video path: ${outputVideoFile.absolutePath}")
                return outputVideoFile.absolutePath
            } else {
                Log.d("MediaPickerPlus", "Processing failed, returning original path: $sourcePath")
                return sourcePath
            }
        } catch (e: Exception) {
            Log.e("MediaPickerPlus", "Error processing video: ${e.message}", e)
            return sourcePath
        }
    }

    private fun createWatermarkBitmap(text: String, fontSize: Float): Bitmap {
        Log.d("MediaPickerPlus", "Creating watermark bitmap with text: '$text', fontSize: $fontSize")
        
        val textPaint = TextPaint().apply {
            color = Color.WHITE
            alpha = 255
            textSize = fontSize
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            isAntiAlias = true
        }
        val strokePaint = TextPaint(textPaint).apply {
            style = Paint.Style.STROKE
            strokeWidth = 3f  // Make stroke thicker
            color = Color.BLACK
        }
        val maxLineWidth = calculateMaxLineWidth(text, textPaint)
        val layoutWidth = max(1, ceil(maxLineWidth).toInt())
        val fillLayout = StaticLayout.Builder.obtain(text, 0, text.length, textPaint, layoutWidth)
            .setAlignment(Layout.Alignment.ALIGN_CENTER)
            .setIncludePad(false)
            .build()
        val strokeLayout = StaticLayout.Builder.obtain(text, 0, text.length, strokePaint, layoutWidth)
            .setAlignment(Layout.Alignment.ALIGN_CENTER)
            .setIncludePad(false)
            .build()

        val textWidth = fillLayout.width.toFloat()
        val textHeight = fillLayout.height.toFloat()
        val strokeOutset = strokePaint.strokeWidth
        val measuredWidth = textWidth + strokeOutset * 2
        val measuredHeight = textHeight + strokeOutset * 2

        // Use standard padding for watermark bitmap creation (internal spacing)
        val padding = 20f

        Log.d("MediaPickerPlus", "Text dimensions: ${measuredWidth}x${measuredHeight}, padding: $padding")

        val watermarkBitmap = Bitmap.createBitmap(
            ceil(measuredWidth + padding * 2).toInt(),
            ceil(measuredHeight + padding * 2).toInt(),
            Bitmap.Config.ARGB_8888
        )
        val canvas = Canvas(watermarkBitmap)

        canvas.save()
        canvas.translate(padding + strokeOutset, padding + strokeOutset)
        strokeLayout.draw(canvas)
        fillLayout.draw(canvas)
        canvas.restore()

        Log.d("MediaPickerPlus", "Watermark bitmap created: ${watermarkBitmap.width}x${watermarkBitmap.height}")
        return watermarkBitmap
    }

    private fun watermarkVideoWithNativeProcessing(
        inputPath: String,
        outputPath: String,
        watermarkBitmap: Bitmap,
        position: String,
        options: HashMap<String, Any>
    ): Boolean {
        return try {
            Log.d("MediaPickerPlus", "Starting FFmpeg video watermarking")
            Log.d("MediaPickerPlus", "Input: $inputPath")
            Log.d("MediaPickerPlus", "Output: $outputPath")
            
            // Verify input file exists
            val inputFile = File(inputPath)
            if (!inputFile.exists() || !inputFile.canRead()) {
                Log.e("MediaPickerPlus", "Input file does not exist or cannot be read: $inputPath")
                return false
            }
            
            Log.d("MediaPickerPlus", "Input file size: ${inputFile.length()} bytes")
            
            // Create output directory if it doesn't exist
            val outputFile = File(outputPath)
            outputFile.parentFile?.mkdirs()
            
            // Get video properties
            val retriever = MediaMetadataRetriever()
            var width = 0
            var height = 0
            var duration = 0L
            var rotation = 0
            
            try {
                retriever.setDataSource(inputPath)
                width = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toInt() ?: 0
                height = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toInt() ?: 0
                duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLong() ?: 0L
                rotation = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toInt() ?: 0
                
                Log.d("MediaPickerPlus", "Video properties: ${width}x${height}, duration: ${duration}ms, rotation: $rotation")
                
                if (width == 0 || height == 0) {
                    Log.e("MediaPickerPlus", "Invalid video dimensions")
                    return false
                }
            } finally {
                retriever.release()
            }
            
            // Calculate effective dimensions after FFmpeg auto-rotation
            // For videos with 90 or 270 degree rotation, the output dimensions will be swapped
            val (effectiveWidth, effectiveHeight) = if (rotation == 90 || rotation == 270) {
                Pair(height, width)
            } else {
                Pair(width, height)
            }
            
            Log.d("MediaPickerPlus", "Effective dimensions after rotation: ${effectiveWidth}x${effectiveHeight}")
            
            // Process video using FFmpeg with effective dimensions
            return processVideoWithFFmpeg(inputPath, outputPath, watermarkBitmap, position, effectiveWidth, effectiveHeight, duration, rotation, options)
            
        } catch (e: Exception) {
            Log.e("MediaPickerPlus", "Error in FFmpeg video processing: ${e.message}", e)
            false
        }
    }
    
    private fun processVideoWithFFmpeg(
        inputPath: String,
        outputPath: String,
        watermarkBitmap: Bitmap,
        position: String,
        videoWidth: Int,
        videoHeight: Int,
        duration: Long,
        rotation: Int,
        options: HashMap<String, Any>
    ): Boolean {
        return try {
            Log.d("MediaPickerPlus", "Processing video with FFmpeg")
            
            // Save watermark bitmap to temporary file
            val watermarkFile = File(context.cacheDir, "watermark_${System.currentTimeMillis()}.png")
            val watermarkOutputStream = FileOutputStream(watermarkFile)
            watermarkBitmap.compress(Bitmap.CompressFormat.PNG, 100, watermarkOutputStream)
            watermarkOutputStream.close()
            
            Log.d("MediaPickerPlus", "Watermark saved to: ${watermarkFile.absolutePath}")
            
            // Get options from provided options parameter
            val maxWidth = (options.get("maxWidth") as? Int) ?: videoWidth
            val maxHeight = (options.get("maxHeight") as? Int) ?: videoHeight
            
            Log.d("MediaPickerPlus", "Max dimensions: ${maxWidth}x${maxHeight}")
            
            // Calculate target dimensions (with aspect ratio preservation)
            var (targetWidth, targetHeight) = calculateTargetDimensions(videoWidth, videoHeight, maxWidth, maxHeight)
            
            // Apply cropping if specified
            val cropInfo = applyCropToVideo(videoWidth, videoHeight, options)
            if (cropInfo != null) {
                targetWidth = cropInfo.width
                targetHeight = cropInfo.height
            }
            
            Log.d("MediaPickerPlus", "Target dimensions: ${targetWidth}x${targetHeight}")
            
            // Calculate watermark position
            // Note: videoWidth and videoHeight are already the effective (post-rotation) dimensions
            val positionEnum = WatermarkPosition.fromString(position)
            val (watermarkX, watermarkY) = calculateWatermarkPosition(
                positionEnum,
                targetWidth,
                targetHeight,
                watermarkBitmap.width,
                watermarkBitmap.height
            )
            
            Log.d("MediaPickerPlus", "Watermark position: ($watermarkX, $watermarkY)")
            
            // Build FFmpeg command
            val command = buildFFmpegCommand(
                inputPath, 
                outputPath, 
                watermarkFile.absolutePath, 
                watermarkX, 
                watermarkY, 
                targetWidth, 
                targetHeight, 
                rotation,
                cropInfo
            )
            
            Log.d("MediaPickerPlus", "FFmpeg command: $command")
            
            // Execute FFmpeg command
            val latch = CountDownLatch(1)
            var success = false
            var errorMessage = ""
            
            val errorLogs = mutableListOf<String>()
            
            val session = FFmpegKit.executeAsync(command,
                { session ->
                    val returnCode = session.returnCode
                    if (ReturnCode.isSuccess(returnCode)) {
                        Log.d("MediaPickerPlus", "FFmpeg processing completed successfully")
                        success = true
                    } else {
                        // Collect error messages from logs
                        val errorSummary = if (errorLogs.isNotEmpty()) {
                            errorLogs.takeLast(5).joinToString("\n")
                        } else {
                            "Return code: $returnCode"
                        }
                        Log.e("MediaPickerPlus", "FFmpeg failed with return code: $returnCode")
                        Log.e("MediaPickerPlus", "FFmpeg error summary: $errorSummary")
                        errorMessage = "FFmpeg processing failed: $errorSummary"
                    }
                    latch.countDown()
                },
                { log ->
                    val message = log.message ?: ""
                    Log.d("MediaPickerPlus", "FFmpeg log: $message")
                    // Collect error-related logs
                    if (message.contains("error", ignoreCase = true) || 
                        message.contains("failed", ignoreCase = true) ||
                        message.contains("Error", ignoreCase = true) ||
                        message.contains("Invalid", ignoreCase = true)) {
                        errorLogs.add(message)
                    }
                },
                { statistics ->
                    val progress = if (duration > 0) {
                        (statistics.time.toFloat() / duration.toFloat() * 100).toInt()
                    } else {
                        0
                    }
                    Log.d("MediaPickerPlus", "FFmpeg progress: $progress% (${statistics.time}ms / ${duration}ms)")
                }
            )
            
            // Wait for completion with timeout
            val completed = latch.await(10, TimeUnit.MINUTES)
            
            // Clean up temporary watermark file
            watermarkFile.delete()
            
            if (!completed) {
                Log.e("MediaPickerPlus", "FFmpeg operation timed out")
                session.cancel()
                return false
            }
            
            if (!success) {
                Log.e("MediaPickerPlus", "FFmpeg operation failed: $errorMessage")
                return false
            }
            
            // Verify output file was created
            val outputFile = File(outputPath)
            if (!outputFile.exists() || outputFile.length() == 0L) {
                Log.e("MediaPickerPlus", "Output file was not created or is empty")
                return false
            }
            
            Log.d("MediaPickerPlus", "FFmpeg processing completed successfully. Output file size: ${outputFile.length()} bytes")
            return true
            
        } catch (e: Exception) {
            Log.e("MediaPickerPlus", "Error in FFmpeg video processing: ${e.message}", e)
            false
        }
    }

    private fun processVideoWithoutWatermark(
        inputPath: String,
        outputPath: String,
        videoWidth: Int,
        videoHeight: Int,
        rotation: Int,
        options: HashMap<String, Any>
    ): Boolean {
        return try {
            val inputVideo = "\"$inputPath\""
            val output = "\"$outputPath\""

            val maxWidth = options["maxWidth"] as? Int ?: videoWidth
            val maxHeight = options["maxHeight"] as? Int ?: videoHeight
            val cropInfo = applyCropToVideo(videoWidth, videoHeight, options)

            val baseWidth = cropInfo?.width ?: videoWidth
            val baseHeight = cropInfo?.height ?: videoHeight
            var (targetWidth, targetHeight) = calculateTargetDimensions(
                baseWidth,
                baseHeight,
                maxWidth,
                maxHeight
            )

            if (targetWidth % 2 != 0) targetWidth -= 1
            if (targetHeight % 2 != 0) targetHeight -= 1

            val filters = mutableListOf<String>()
            if (cropInfo != null) {
                filters.add("crop=${cropInfo.width}:${cropInfo.height}:${cropInfo.x}:${cropInfo.y}")
            }
            if (targetWidth != baseWidth || targetHeight != baseHeight) {
                filters.add("scale=$targetWidth:$targetHeight")
            }

            val filterArg = if (filters.isNotEmpty()) {
                "-vf \"${filters.joinToString(",")}\""
            } else {
                ""
            }

            val targetBitrate = options["targetBitrate"] as? Int ?: options["videoBitrate"] as? Int
            val bitrateArg = if (targetBitrate != null) {
                "-b:v $targetBitrate"
            } else {
                ""
            }

            val command = "-i $inputVideo $filterArg $bitrateArg -c:a copy -c:v mpeg4 -q:v 5 -y $output"

            val latch = CountDownLatch(1)
            var success = false
            var errorMessage = ""

            val session = FFmpegKit.executeAsync(command,
                { session ->
                    val returnCode = session.returnCode
                    if (ReturnCode.isSuccess(returnCode)) {
                        success = true
                    } else {
                        errorMessage = "FFmpeg processing failed with code: $returnCode"
                    }
                    latch.countDown()
                },
                { log ->
                    Log.d("MediaPickerPlus", "FFmpeg log: ${log.message}")
                },
                { statistics ->
                    Log.d("MediaPickerPlus", "FFmpeg statistics: time=${statistics.time}ms, size=${statistics.size}")
                }
            )

            val completed = latch.await(10, TimeUnit.MINUTES)

            if (!completed) {
                session.cancel()
                return false
            }

            if (!success) {
                Log.e("MediaPickerPlus", errorMessage)
                return false
            }

            val outputFile = File(outputPath)
            outputFile.exists() && outputFile.length() > 0L
        } catch (e: Exception) {
            Log.e("MediaPickerPlus", "Error processing video without watermark: ${e.message}", e)
            false
        }
    }
    
    private fun calculateTargetDimensions(originalWidth: Int, originalHeight: Int, maxWidth: Int, maxHeight: Int): Pair<Int, Int> {
        if (originalWidth <= maxWidth && originalHeight <= maxHeight) {
            return Pair(originalWidth, originalHeight)
        }
        
        val aspectRatio = originalWidth.toFloat() / originalHeight.toFloat()
        
        var targetWidth: Int
        var targetHeight: Int
        
        if (originalWidth > originalHeight) {
            // Landscape
            targetWidth = minOf(maxWidth, originalWidth)
            targetHeight = (targetWidth / aspectRatio).toInt()
            
            if (targetHeight > maxHeight) {
                targetHeight = maxHeight
                targetWidth = (targetHeight * aspectRatio).toInt()
            }
        } else {
            // Portrait
            targetHeight = minOf(maxHeight, originalHeight)
            targetWidth = (targetHeight * aspectRatio).toInt()
            
            if (targetWidth > maxWidth) {
                targetWidth = maxWidth
                targetHeight = (targetWidth / aspectRatio).toInt()
            }
        }
        
        return Pair(targetWidth, targetHeight)
    }
    
    private fun calculateWatermarkPosition(
        position: WatermarkPosition,
        videoWidth: Int,
        videoHeight: Int,
        watermarkWidth: Int,
        watermarkHeight: Int
    ): Pair<Int, Int> {
        // Calculate 2% padding based on shorter edge for consistent positioning
        val shorterEdge = minOf(videoWidth, videoHeight)
        val edgePadding = (shorterEdge * 0.02f).toInt() // 2% of shorter edge
        
        return when (position) {
            WatermarkPosition.TOP_LEFT -> Pair(edgePadding, edgePadding)
            WatermarkPosition.TOP_CENTER -> Pair((videoWidth - watermarkWidth) / 2, edgePadding)
            WatermarkPosition.TOP_RIGHT -> Pair(videoWidth - watermarkWidth - edgePadding, edgePadding)
            WatermarkPosition.MIDDLE_LEFT -> Pair(edgePadding, (videoHeight - watermarkHeight) / 2)
            WatermarkPosition.CENTER -> Pair((videoWidth - watermarkWidth) / 2, (videoHeight - watermarkHeight) / 2)
            WatermarkPosition.MIDDLE_RIGHT -> Pair(videoWidth - watermarkWidth - edgePadding, (videoHeight - watermarkHeight) / 2)
            WatermarkPosition.BOTTOM_LEFT -> Pair(edgePadding, videoHeight - watermarkHeight - edgePadding)
            WatermarkPosition.BOTTOM_CENTER -> Pair((videoWidth - watermarkWidth) / 2, videoHeight - watermarkHeight - edgePadding)
            WatermarkPosition.BOTTOM_RIGHT -> Pair(videoWidth - watermarkWidth - edgePadding, videoHeight - watermarkHeight - edgePadding)
        }
    }
    
    data class VideoCropInfo(
        val x: Int,
        val y: Int,
        val width: Int,
        val height: Int
    )

    private fun applyCropToVideo(videoWidth: Int, videoHeight: Int, options: HashMap<String, Any>?): VideoCropInfo? {
        if (options == null || !options.containsKey("cropOptions")) return null
        
        val cropOptionsMap = options["cropOptions"] as? HashMap<String, Any> ?: return null
        if (cropOptionsMap["enableCrop"] != true) return null
        
        val cropRect = cropOptionsMap["cropRect"] as? HashMap<String, Any>
        if (cropRect != null) {
            // Use specified crop rectangle
            val x = (cropRect["x"] as? Double)?.toInt() ?: 0
            val y = (cropRect["y"] as? Double)?.toInt() ?: 0
            val width = (cropRect["width"] as? Double)?.toInt() ?: videoWidth
            val height = (cropRect["height"] as? Double)?.toInt() ?: videoHeight
            
            // Ensure crop bounds are within video bounds
            val croppedX = maxOf(0, minOf(x, videoWidth))
            val croppedY = maxOf(0, minOf(y, videoHeight))
            val croppedWidth = minOf(width, videoWidth - croppedX)
            val croppedHeight = minOf(height, videoHeight - croppedY)
            
            if (croppedWidth > 0 && croppedHeight > 0) {
                return VideoCropInfo(croppedX, croppedY, croppedWidth, croppedHeight)
            }
        } else if (cropOptionsMap["aspectRatio"] != null) {
            // Apply aspect ratio cropping
            val aspectRatio = (cropOptionsMap["aspectRatio"] as? Double)?.toFloat() ?: 1.0f
            return applyCropWithAspectRatioToVideo(videoWidth, videoHeight, aspectRatio)
        }
        
        return null
    }

    private fun applyCropWithAspectRatioToVideo(videoWidth: Int, videoHeight: Int, aspectRatio: Float): VideoCropInfo {
        val originalWidth = videoWidth.toFloat()
        val originalHeight = videoHeight.toFloat()
        val originalAspectRatio = originalWidth / originalHeight

        val newWidth: Int
        val newHeight: Int
        val x: Int
        val y: Int

        if (originalAspectRatio > aspectRatio) {
            // Original is wider, crop width
            newHeight = videoHeight
            newWidth = (videoHeight * aspectRatio).toInt()
            x = ((videoWidth - newWidth) / 2)
            y = 0
        } else {
            // Original is taller, crop height
            newWidth = videoWidth
            newHeight = (videoWidth / aspectRatio).toInt()
            x = 0
            y = ((videoHeight - newHeight) / 2)
        }

        return VideoCropInfo(x, y, newWidth, newHeight)
    }

    private fun buildFFmpegCommand(
        inputPath: String,
        outputPath: String,
        watermarkPath: String,
        watermarkX: Int,
        watermarkY: Int,
        targetWidth: Int,
        targetHeight: Int,
        rotation: Int,
        cropInfo: VideoCropInfo?
    ): String {
        val inputVideo = "\"$inputPath\""
        val watermarkImage = "\"$watermarkPath\""
        val output = "\"$outputPath\""
        
        // Build video filters
        val videoFilters = mutableListOf<String>()
        
        // Add crop filter if needed
        if (cropInfo != null) {
            val cropFilter = "crop=${cropInfo.width}:${cropInfo.height}:${cropInfo.x}:${cropInfo.y}"
            videoFilters.add(cropFilter)
        }
        
        // Add scaling filter
        // Note: FFmpeg auto-rotates videos by default based on rotation metadata,
        // so we use the effective (post-rotation) dimensions for scaling.
        // The targetWidth/targetHeight should already account for rotation.
        val scaleFilter = "scale=$targetWidth:$targetHeight"
        videoFilters.add(scaleFilter)
        
        // Note: We don't add explicit rotation filters because FFmpeg's -autorotate
        // (enabled by default) handles rotation based on the video's display matrix.
        // Adding explicit transpose filters would cause double rotation.
        
        // Build overlay filter
        val overlayFilter = "overlay=$watermarkX:$watermarkY"
        
        val filterComplex = if (videoFilters.isEmpty()) {
            "[0:v][1:v]$overlayFilter"
        } else {
            "[0:v]${videoFilters.joinToString(",")}[scaled];[scaled][1:v]$overlayFilter"
        }
        
        // Build complete FFmpeg command
        // Note: Removed -preset fast as it's not supported in ffmpeg-kit-https variant
        // Using mpeg4 encoder instead of libx264 for better compatibility
        return "-i $inputVideo -i $watermarkImage -filter_complex \"$filterComplex\" -c:a copy -c:v mpeg4 -q:v 5 -y $output"
    }

    private fun applyCropToBitmap(bitmap: Bitmap, cropOptions: HashMap<String, Any>): Bitmap {
        val cropRect = cropOptions["cropRect"] as? HashMap<String, Any>
        if (cropRect != null) {
            // Use specified crop rectangle
            val x = (cropRect["x"] as? Double)?.toInt() ?: 0
            val y = (cropRect["y"] as? Double)?.toInt() ?: 0
            val width = (cropRect["width"] as? Double)?.toInt() ?: bitmap.width
            val height = (cropRect["height"] as? Double)?.toInt() ?: bitmap.height
            
            // Ensure crop bounds are within bitmap bounds
            val croppedX = maxOf(0, minOf(x, bitmap.width))
            val croppedY = maxOf(0, minOf(y, bitmap.height))
            val croppedWidth = minOf(width, bitmap.width - croppedX)
            val croppedHeight = minOf(height, bitmap.height - croppedY)
            
            if (croppedWidth > 0 && croppedHeight > 0) {
                return Bitmap.createBitmap(bitmap, croppedX, croppedY, croppedWidth, croppedHeight)
            }
        } else if (cropOptions["aspectRatio"] != null) {
            // Apply aspect ratio cropping
            val aspectRatio = (cropOptions["aspectRatio"] as? Double)?.toFloat() ?: 1.0f
            return applyCropWithAspectRatio(bitmap, aspectRatio)
        }
        
        return bitmap
    }

    private fun applyCropWithAspectRatio(bitmap: Bitmap, aspectRatio: Float): Bitmap {
        val originalWidth = bitmap.width.toFloat()
        val originalHeight = bitmap.height.toFloat()
        val originalAspectRatio = originalWidth / originalHeight

        val newWidth: Int
        val newHeight: Int
        val x: Int
        val y: Int

        if (originalAspectRatio > aspectRatio) {
            // Original is wider, crop width
            newHeight = originalHeight.toInt()
            newWidth = (originalHeight * aspectRatio).toInt()
            x = ((originalWidth - newWidth) / 2).toInt()
            y = 0
        } else {
            // Original is taller, crop height
            newWidth = originalWidth.toInt()
            newHeight = (originalWidth / aspectRatio).toInt()
            x = 0
            y = ((originalHeight - newHeight) / 2).toInt()
        }

        return Bitmap.createBitmap(bitmap, x, y, newWidth, newHeight)
    }

    private fun pickFile(allowedExtensions: List<String>?) {
        val activity = activity ?: return
        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            type = "*/*"
            addCategory(Intent.CATEGORY_OPENABLE)
            if (!allowedExtensions.isNullOrEmpty()) {
                val mimeTypes = allowedExtensions.mapNotNull { ext ->
                    getMimeTypeFromExtension(ext)
                }.toTypedArray()
                if (mimeTypes.isNotEmpty()) {
                    putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes)
                }
            }
        }
        activity.startActivityForResult(intent, REQUEST_PICK_FILE)
    }

    private fun pickMultipleFiles(allowedExtensions: List<String>?) {
        val activity = activity ?: return
        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            type = "*/*"
            addCategory(Intent.CATEGORY_OPENABLE)
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            if (!allowedExtensions.isNullOrEmpty()) {
                val mimeTypes = allowedExtensions.mapNotNull { ext ->
                    getMimeTypeFromExtension(ext)
                }.toTypedArray()
                if (mimeTypes.isNotEmpty()) {
                    putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes)
                }
            }
        }
        activity.startActivityForResult(intent, REQUEST_PICK_MULTIPLE_FILES)
    }

    private fun pickMultipleMedia(source: String?, type: String?) {
        val activity = activity ?: return
        when (source) {
            "gallery" -> {
                val intent = Intent(Intent.ACTION_PICK).apply {
                    when (type) {
                        "image" -> setDataAndType(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, "image/*")
                        "video" -> setDataAndType(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, "video/*")
                        else -> setDataAndType(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, "image/*,video/*")
                    }
                    putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
                }
                activity.startActivityForResult(intent, REQUEST_PICK_MULTIPLE_MEDIA)
            }
            else -> {
                pendingResult?.error("INVALID_SOURCE", "Multiple media picking only supports gallery source", null)
            }
        }
    }

    private fun getMimeTypeFromExtension(extension: String): String? {
        return when (extension.lowercase()) {
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            "gif" -> "image/gif"
            "webp" -> "image/webp"
            "mp4" -> "video/mp4"
            "mov" -> "video/quicktime"
            "avi" -> "video/x-msvideo"
            "mkv" -> "video/x-matroska"
            "pdf" -> "application/pdf"
            "doc" -> "application/msword"
            "docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            "xls" -> "application/vnd.ms-excel"
            "xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            "txt" -> "text/plain"
            "mp3" -> "audio/mpeg"
            "wav" -> "audio/wav"
            "aac" -> "audio/aac"
            else -> null
        }
    }
    
    private fun isPhotoPickerAvailable(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Check if the photo picker is available on this device
            // Some devices might not have it even on Android 13+
            try {
                val intent = Intent(MediaStore.ACTION_PICK_IMAGES)
                activity?.packageManager?.queryIntentActivities(intent, 0)?.isNotEmpty() == true
            } catch (e: Exception) {
                false
            }
        } else {
            false
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (resultCode == Activity.RESULT_OK) {
            when (requestCode) {
                REQUEST_IMAGE_CAPTURE -> {
                    val result = pendingResult
                    pendingResult = null
                    val capturePath = currentMediaPath
                    currentMediaPath = null
                    // Snapshot mediaOptions to avoid race conditions with concurrent requests
                    val optionsSnapshot = mediaOptions?.let { HashMap(it) }

                    capturePath?.let { path ->
                        Thread {
                            val processedPath = if (optionsSnapshot != null) {
                                processImageWithOptions(path, optionsSnapshot)
                            } else {
                                path
                            }
                            runOnUiThread {
                                result?.success(processedPath)
                            }
                        }.start()
                    }
                    return true
                }
                REQUEST_VIDEO_CAPTURE -> {
                    val capturedPath = currentMediaPath?.let { path ->
                        val file = File(path)
                        if (file.exists() && file.length() > 0L) path else null
                    } ?: data?.data?.let { uri ->
                        getFilePathFromUri(uri)
                    }

                    val result = pendingResult
                    pendingResult = null
                    currentMediaPath = null
                    // Snapshot mediaOptions to avoid race conditions with concurrent requests
                    val optionsSnapshot = mediaOptions?.let { HashMap(it) }

                    if (capturedPath != null) {
                        Thread {
                            val processedPath = if (optionsSnapshot != null) {
                                processVideoWithOptions(capturedPath, optionsSnapshot)
                            } else {
                                capturedPath
                            }
                            runOnUiThread {
                                result?.success(processedPath)
                            }
                        }.start()
                    } else {
                        result?.error("NO_FILE", "No video file was captured", null)
                    }
                    return true
                }
                REQUEST_PICK_IMAGE -> {
                    val result = pendingResult
                    pendingResult = null
                    // Snapshot mediaOptions to avoid race conditions with concurrent requests
                    val optionsSnapshot = mediaOptions?.let { HashMap(it) }

                    data?.data?.let { uri ->
                        val filePath = getFilePathFromUri(uri)
                        filePath?.let { path ->
                            Thread {
                                val processedPath = if (optionsSnapshot != null) {
                                    processImageWithOptions(path, optionsSnapshot)
                                } else {
                                    path
                                }
                                runOnUiThread {
                                    result?.success(processedPath)
                                }
                            }.start()
                        } ?: run {
                            result?.error(
                                "NO_FILE",
                                "Could not get file path from URI",
                                null
                            )
                        }
                    } ?: run {
                        result?.error("NO_FILE", "No file was selected", null)
                    }
                    return true
                }
                REQUEST_PICK_VIDEO -> {
                    val result = pendingResult
                    pendingResult = null
                    // Snapshot mediaOptions to avoid race conditions with concurrent requests
                    val optionsSnapshot = mediaOptions?.let { HashMap(it) }

                    data?.data?.let { uri ->
                        val filePath = getFilePathFromUri(uri)
                        filePath?.let { path ->
                            Thread {
                                val processedPath = if (optionsSnapshot != null) {
                                    processVideoWithOptions(path, optionsSnapshot)
                                } else {
                                    path
                                }
                                runOnUiThread {
                                    result?.success(processedPath)
                                }
                            }.start()
                        } ?: run {
                            result?.error(
                                "NO_FILE",
                                "Could not get file path from URI",
                                null
                            )
                        }
                    } ?: run {
                        result?.error("NO_FILE", "No file was selected", null)
                    }
                    return true
                }
                REQUEST_PICK_FILE -> {
                    data?.data?.let { uri ->
                        val filePath = getFilePathFromUri(uri)
                        filePath?.let { path ->
                            pendingResult?.success(path)
                        } ?: run {
                            pendingResult?.error(
                                "NO_FILE",
                                "Could not get file path from URI",
                                null
                            )
                        }
                    } ?: run {
                        pendingResult?.error("NO_FILE", "No file was selected", null)
                    }
                    pendingResult = null
                    return true
                }
                REQUEST_PICK_MULTIPLE_FILES -> {
                    val result = pendingResult
                    pendingResult = null

                    val selectedUris = mutableListOf<Uri>()
                    data?.clipData?.let { clipData ->
                        for (i in 0 until clipData.itemCount) {
                            selectedUris.add(clipData.getItemAt(i).uri)
                        }
                    } ?: data?.data?.let { uri ->
                        selectedUris.add(uri)
                    }

                    if (selectedUris.isEmpty()) {
                        result?.error("NO_FILE", "No files were selected", null)
                        return true
                    }

                    Thread {
                        val filePaths = mutableListOf<String>()
                        for (uri in selectedUris) {
                            val filePath = getFilePathFromUri(uri)
                            filePath?.let { filePaths.add(it) }
                        }

                        runOnUiThread {
                            if (filePaths.isNotEmpty()) {
                                result?.success(filePaths)
                            } else {
                                result?.error("NO_FILE", "No files were selected", null)
                            }
                        }
                    }.start()
                    return true
                }
                REQUEST_PICK_MULTIPLE_MEDIA -> {
                    val result = pendingResult
                    pendingResult = null

                    val selectedUris = mutableListOf<Uri>()
                    data?.clipData?.let { clipData ->
                        for (i in 0 until clipData.itemCount) {
                            selectedUris.add(clipData.getItemAt(i).uri)
                        }
                    } ?: data?.data?.let { uri ->
                        selectedUris.add(uri)
                    }

                    if (selectedUris.isEmpty()) {
                        result?.error("NO_FILE", "No media files were selected", null)
                        return true
                    }

                    // Snapshot mediaOptions to avoid race conditions with concurrent requests
                    val optionsSnapshot = mediaOptions?.let { HashMap(it) }

                    Thread {
                        val filePaths = mutableListOf<String>()
                        for (uri in selectedUris) {
                            val filePath = getFilePathFromUri(uri)
                            filePath?.let { path ->
                                val processedPath = if (optionsSnapshot != null) {
                                    if (isImageFile(path)) {
                                        processImageWithOptions(path, optionsSnapshot)
                                    } else if (isVideoFile(path)) {
                                        processVideoWithOptions(path, optionsSnapshot)
                                    } else {
                                        path
                                    }
                                } else {
                                    path
                                }
                                filePaths.add(processedPath)
                            }
                        }

                        runOnUiThread {
                            if (filePaths.isNotEmpty()) {
                                result?.success(filePaths)
                            } else {
                                result?.error("NO_FILE", "No media files were selected", null)
                            }
                        }
                    }.start()
                    return true
                }
                REQUEST_PHOTO_PICKER -> {
                    val result = pendingResult
                    pendingResult = null

                    // Handle modern Photo Picker result
                    // Snapshot mediaOptions to avoid race conditions with concurrent requests
                    val optionsSnapshot = mediaOptions?.let { HashMap(it) }

                    data?.data?.let { uri ->
                        val filePath = getFilePathFromUri(uri)
                        filePath?.let { path ->
                            Thread {
                                val processedPath = if (optionsSnapshot != null) {
                                    processImageWithOptions(path, optionsSnapshot)
                                } else {
                                    path
                                }
                                runOnUiThread {
                                    result?.success(processedPath)
                                }
                            }.start()
                        } ?: run {
                            result?.error(
                                "NO_FILE",
                                "Could not get file path from URI",
                                null
                            )
                        }
                    } ?: run {
                        result?.error("NO_FILE", "No file was selected", null)
                    }
                    return true
                }
            }
        } else if (resultCode == Activity.RESULT_CANCELED) {
            pendingResult?.success(null)
            pendingResult = null
            return true
        }
        return false
    }

    private fun isImageFile(path: String): Boolean {
        val extension = path.substringAfterLast('.', "").lowercase()
        return extension in listOf("jpg", "jpeg", "png", "gif", "webp", "bmp")
    }

    private fun isVideoFile(path: String): Boolean {
        val extension = path.substringAfterLast('.', "").lowercase()
        return extension in listOf("mp4", "mov", "avi", "mkv", "webm", "m4v", "3gp")
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        when (requestCode) {
            REQUEST_CAMERA_PERMISSION -> {
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    // For standalone permission requests (not part of media picking)
                    if (pendingResult != null && (mediaOptions == null || currentMediaAction == null)) {
                        pendingResult?.success(true)
                    }
                    // For media picking, continue with the action
                    currentMediaAction?.invoke()
                } else {
                    pendingResult?.error("PERMISSION_DENIED", "Camera permission denied", null)
                }
                pendingResult = null
                currentMediaAction = null
                return true
            }
            REQUEST_GALLERY_PERMISSION -> {
                if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                    // For standalone permission requests (not part of media picking)
                    if (pendingResult != null && (mediaOptions == null || currentMediaAction == null)) {
                        pendingResult?.success(true)
                    }
                    // For media picking, continue with the action
                    currentMediaAction?.invoke()
                } else {
                    pendingResult?.error("PERMISSION_DENIED", "Gallery permission denied", null)
                }
                pendingResult = null
                currentMediaAction = null
                return true
            }
            REQUEST_MICROPHONE_PERMISSION -> {
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    recordVideo()
                } else {
                    pendingResult?.error("PERMISSION_DENIED", "Microphone permission denied", null)
                    pendingResult = null
                }
                return true
            }
        }
        return false
    }

    private fun processImage(imagePath: String, options: HashMap<String, Any>, result: Result) {
        try {
            val inputFile = File(imagePath)
            if (!inputFile.exists()) {
                result.error("FILE_NOT_FOUND", "Image file not found", null)
                return
            }

            // Create output file
            val outputFile = File(context.cacheDir, "processed_${System.currentTimeMillis()}.jpg")
            
            // Load original bitmap
            val originalBitmap = BitmapFactory.decodeFile(imagePath)
            if (originalBitmap == null) {
                result.error("INVALID_IMAGE", "Unable to decode image file", null)
                return
            }

            var processedBitmap = originalBitmap

            // Apply cropping if specified
            val cropOptions = options["cropOptions"] as? HashMap<String, Any>
            if (cropOptions != null) {
                val enableCrop = cropOptions["enableCrop"] as? Boolean ?: false
                if (enableCrop) {
                    processedBitmap = applyCropToBitmap(processedBitmap, cropOptions)
                }
            }

            // Apply watermark if specified
            val watermark = options["watermark"] as? String
            if (!watermark.isNullOrEmpty()) {
                val watermarkFontSize = calculateWatermarkFontSize(options, processedBitmap.width, processedBitmap.height, 30f)
                val watermarkPosition = options["watermarkPosition"] as? String ?: "bottomRight"
                processedBitmap = addWatermarkToBitmap(processedBitmap, watermark, watermarkFontSize, watermarkPosition)
            }

            // Apply image quality and save
            val quality = (options["imageQuality"] as? Number)?.toInt() ?: 80
            val outputStream = FileOutputStream(outputFile)
            processedBitmap.compress(Bitmap.CompressFormat.JPEG, quality, outputStream)
            outputStream.close()

            // Clean up
            if (processedBitmap != originalBitmap) {
                processedBitmap.recycle()
            }
            originalBitmap.recycle()

            result.success(outputFile.absolutePath)
        } catch (e: Exception) {
            Log.e("MediaPickerPlus", "Error processing image: ${e.message}", e)
            result.error("PROCESSING_ERROR", "Error processing image: ${e.message}", null)
        }
    }
    
    private fun addWatermarkToExistingImage(imagePath: String, options: HashMap<String, Any>, result: Result) {
        try {
            // Validate input image path
            val inputFile = File(imagePath)
            if (!inputFile.exists()) {
                result.error("FILE_NOT_FOUND", "Image file not found", null)
                return
            }

            // Check if watermark is specified
            val watermarkText = options["watermark"] as? String
            if (watermarkText.isNullOrEmpty()) {
                result.error("INVALID_ARGUMENTS", "Watermark text is required", null)
                return
            }

            // Load original bitmap
            val originalBitmap = BitmapFactory.decodeFile(imagePath)
            if (originalBitmap == null) {
                result.error("INVALID_IMAGE", "Unable to decode image file", null)
                return
            }

            // Apply watermark
            val fontSize = calculateWatermarkFontSize(options, originalBitmap.width, originalBitmap.height, 30f)
            val position = options["watermarkPosition"] as? String ?: "bottomRight"
            val watermarkedBitmap = addWatermarkToBitmap(originalBitmap, watermarkText, fontSize, position)

            // Create output file
            val timeStamp = generateTimestamp()
            val outputFileName = "watermarked_image_${timeStamp}.jpg"
            val outputFile = File(context.cacheDir, outputFileName)

            // Save watermarked image
            val quality = (options["imageQuality"] as? Number)?.toInt() ?: 80
            val outputStream = FileOutputStream(outputFile)
            watermarkedBitmap.compress(Bitmap.CompressFormat.JPEG, quality, outputStream)
            outputStream.close()

            // Clean up
            if (watermarkedBitmap != originalBitmap) {
                watermarkedBitmap.recycle()
            }
            originalBitmap.recycle()

            result.success(outputFile.absolutePath)
        } catch (e: Exception) {
            Log.e("MediaPickerPlus", "Error adding watermark to image: ${e.message}", e)
            result.error("WATERMARK_ERROR", "Error adding watermark to image: ${e.message}", null)
        }
    }
    
    private fun addWatermarkToExistingVideo(videoPath: String, options: HashMap<String, Any>, result: Result) {
        try {
            // Validate input video path
            val inputFile = File(videoPath)
            if (!inputFile.exists()) {
                result.error("FILE_NOT_FOUND", "Video file not found", null)
                return
            }

            // Check if watermark is specified
            val watermarkText = options["watermark"] as? String
            if (watermarkText.isNullOrEmpty()) {
                result.error("INVALID_ARGUMENTS", "Watermark text is required", null)
                return
            }

            // Create output file
            val timeStamp = generateTimestamp()
            val outputFileName = "watermarked_video_${timeStamp}.mp4"
            val outputFile = File(context.cacheDir, outputFileName)

            // Get video dimensions to calculate font size
            val retriever = MediaMetadataRetriever()
            var videoWidth = 1920  // Default fallback
            var videoHeight = 1080 // Default fallback
            try {
                retriever.setDataSource(videoPath)
                videoWidth = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toInt() ?: 1920
                videoHeight = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toInt() ?: 1080
            } finally {
                retriever.release()
            }

            // Create watermark bitmap with calculated font size
            val fontSize = calculateWatermarkFontSize(options, videoWidth, videoHeight, 48f)
            val position = options["watermarkPosition"] as? String ?: "bottomRight"
            val watermarkBitmap = createWatermarkBitmap(watermarkText, fontSize)

            // Process video with watermark
            val success = watermarkVideoWithNativeProcessing(
                videoPath,
                outputFile.absolutePath,
                watermarkBitmap,
                position,
                options
            )

            if (success) {
                result.success(outputFile.absolutePath)
            } else {
                result.error("WATERMARK_ERROR", "Failed to add watermark to video", null)
            }
        } catch (e: Exception) {
            Log.e("MediaPickerPlus", "Error adding watermark to video: ${e.message}", e)
            result.error("WATERMARK_ERROR", "Error adding watermark to video: ${e.message}", null)
        }
    }
    
    private fun extractThumbnail(videoPath: String, timeInSeconds: Double, options: HashMap<String, Any>?, result: Result) {
        Thread {
            try {
                // Validate input video path
                val inputFile = File(videoPath)
                if (!inputFile.exists()) {
                    runOnUiThread {
                        result.error("FILE_NOT_FOUND", "Video file not found", null)
                    }
                    return@Thread
                }

                // Create output file for thumbnail
                val timeStamp = generateTimestamp()
                val thumbnailFileName = "thumbnail_${timeStamp}.jpg"
                val outputFile = File(context.cacheDir, thumbnailFileName)

                // Extract thumbnail using FFmpeg
                val success = extractThumbnailWithFFmpeg(
                    videoPath,
                    outputFile.absolutePath,
                    timeInSeconds,
                    options
                )

                if (success) {
                    // Use processImageWithOptions directly to avoid race condition
                    // by not mutating the global mediaOptions from a background thread
                    val processedPath = if (options != null && options.isNotEmpty()) {
                        processImageWithOptions(outputFile.absolutePath, options)
                    } else {
                        outputFile.absolutePath
                    }
                    runOnUiThread {
                        result.success(processedPath)
                    }
                } else {
                    runOnUiThread {
                        result.error(
                            "EXTRACTION_ERROR",
                            "Failed to extract thumbnail from video",
                            null
                        )
                    }
                }
            } catch (e: Exception) {
                Log.e("MediaPickerPlus", "Error extracting thumbnail: ${e.message}", e)
                runOnUiThread {
                    result.error(
                        "EXTRACTION_ERROR",
                        "Error extracting thumbnail: ${e.message}",
                        null
                    )
                }
            }
        }.start()
    }
    
    private fun extractThumbnailWithFFmpeg(inputPath: String, outputPath: String, timeInSeconds: Double, options: HashMap<String, Any>?): Boolean {
        return try {
            Log.d("MediaPickerPlus", "Extracting thumbnail with FFmpeg")
            Log.d("MediaPickerPlus", "Input: $inputPath")
            Log.d("MediaPickerPlus", "Output: $outputPath")
            Log.d("MediaPickerPlus", "Time: ${timeInSeconds}s")
            
            // Verify input file exists
            val inputFile = File(inputPath)
            if (!inputFile.exists() || !inputFile.canRead()) {
                Log.e("MediaPickerPlus", "Input file does not exist or cannot be read: $inputPath")
                return false
            }
            
            Log.d("MediaPickerPlus", "Input file size: ${inputFile.length()} bytes")
            
            // Create output directory if it doesn't exist
            val outputFile = File(outputPath)
            outputFile.parentFile?.mkdirs()
            
            // Get video metadata
            val retriever = MediaMetadataRetriever()
            var duration = 0L
            var width = 0
            var height = 0
            
            try {
                retriever.setDataSource(inputPath)
                duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLong() ?: 0L
                width = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toInt() ?: 0
                height = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toInt() ?: 0
                
                Log.d("MediaPickerPlus", "Video properties: ${width}x${height}, duration: ${duration}ms")
            } finally {
                retriever.release()
            }
            
            // Ensure the time is within video duration
            val maxTimeInSeconds = if (duration > 0) duration / 1000.0 else Double.MAX_VALUE
            val actualTimeInSeconds = minOf(timeInSeconds, maxTimeInSeconds - 0.1) // Leave small buffer
            
            // Calculate target dimensions if resize options are provided
            var targetWidth = width
            var targetHeight = height
            if (options != null) {
                val maxWidth = options["maxWidth"] as? Int ?: width
                val maxHeight = options["maxHeight"] as? Int ?: height
                
                if (maxWidth > 0 && maxHeight > 0 && (width > maxWidth || height > maxHeight)) {
                    val (newWidth, newHeight) = calculateTargetDimensions(width, height, maxWidth, maxHeight)
                    targetWidth = newWidth
                    targetHeight = newHeight
                }
            }
            
            // Build FFmpeg command for thumbnail extraction
            val inputVideo = "\"$inputPath\""
            val output = "\"$outputPath\""
            val timeStr = String.format(Locale.US, "%.2f", actualTimeInSeconds)
            
            // Build the FFmpeg command
            // -ss: seek to specific time
            // -i: input file
            // -vframes 1: extract only one frame
            // -q:v 2: high quality for JPEG output (scale 2-31, where 2 is highest quality)
            // -vf scale: resize if needed
            val scaleFilter = if (targetWidth != width || targetHeight != height) {
                "-vf scale=${targetWidth}:${targetHeight}"
            } else {
                ""
            }
            
            val command = "-ss $timeStr -i $inputVideo $scaleFilter -vframes 1 -q:v 2 -y $output"
            
            Log.d("MediaPickerPlus", "FFmpeg command: $command")
            
            // Execute FFmpeg command
            val latch = CountDownLatch(1)
            var success = false
            var errorMessage = ""
            
            val session = FFmpegKit.executeAsync(command,
                { session ->
                    val returnCode = session.returnCode
                    if (ReturnCode.isSuccess(returnCode)) {
                        Log.d("MediaPickerPlus", "FFmpeg thumbnail extraction completed successfully")
                        success = true
                    } else {
                        Log.e("MediaPickerPlus", "FFmpeg failed with return code: $returnCode")
                        errorMessage = "FFmpeg thumbnail extraction failed with code: $returnCode"
                    }
                    latch.countDown()
                },
                { log ->
                    Log.d("MediaPickerPlus", "FFmpeg log: ${log.message}")
                },
                { statistics ->
                    // Statistics callback for progress tracking (not really needed for single frame)
                    Log.d("MediaPickerPlus", "FFmpeg statistics: time=${statistics.time}ms, size=${statistics.size}")
                }
            )
            
            // Wait for completion with timeout
            val completed = latch.await(30, TimeUnit.SECONDS)
            
            if (!completed) {
                Log.e("MediaPickerPlus", "FFmpeg thumbnail extraction timed out")
                session.cancel()
                return false
            }
            
            if (!success) {
                Log.e("MediaPickerPlus", "FFmpeg thumbnail extraction failed: $errorMessage")
                return false
            }
            
            // Verify output file was created
            if (!outputFile.exists() || outputFile.length() == 0L) {
                Log.e("MediaPickerPlus", "Thumbnail output file was not created or is empty")
                return false
            }
            
            Log.d("MediaPickerPlus", "FFmpeg thumbnail extraction completed successfully. Output file size: ${outputFile.length()} bytes")
            return true
            
        } catch (e: Exception) {
            Log.e("MediaPickerPlus", "Error in FFmpeg thumbnail extraction: ${e.message}", e)
            false
        }
    }
    
    /**
     * Universal video processing method that applies all video transformations:
     * - Resizing (within targetWidth and targetHeight)
     * - Video quality compression
     * - Watermarking
     */
    private fun applyVideo(videoPath: String, options: HashMap<String, Any>, result: Result) {
        try {
            // Validate input video path
            val inputFile = File(videoPath)
            if (!inputFile.exists()) {
                result.error("FILE_NOT_FOUND", "Video file not found", null)
                return
            }

            // Create output file
            val timeStamp = generateTimestamp()
            val outputFileName = "processed_video_${timeStamp}.mp4"
            val outputFile = File(context.cacheDir, outputFileName)

            val watermarkText = options["watermark"] as? String
            val watermarkPosition = options["watermarkPosition"] as? String ?: "bottomRight"
            val deleteOriginal = options["deleteOriginalFile"] as? Boolean ?: false

            // If watermarking is needed, use the existing watermarkVideoWithNativeProcessing function
            if (!watermarkText.isNullOrEmpty()) {
                // Get video dimensions to calculate font size
                val retriever = MediaMetadataRetriever()
                var videoWidth = 1920
                var videoHeight = 1080
                try {
                    retriever.setDataSource(videoPath)
                    videoWidth = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toInt() ?: 1920
                    videoHeight = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toInt() ?: 1080
                    val rotation = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toInt() ?: 0
                    
                    // For rotated videos, swap dimensions for font size calculation
                    if (rotation == 90 || rotation == 270) {
                        val temp = videoWidth
                        videoWidth = videoHeight
                        videoHeight = temp
                    }
                } finally {
                    retriever.release()
                }
                
                // Calculate font size and create watermark bitmap
                // Note: options is passed directly, no need to mutate global mediaOptions
                val fontSize = calculateWatermarkFontSize(options, videoWidth, videoHeight, 48f)
                val watermarkBitmap = createWatermarkBitmap(watermarkText, fontSize)
                
                // Process video using existing watermarkVideoWithNativeProcessing function
                Thread {
                    val success = watermarkVideoWithNativeProcessing(
                        videoPath,
                        outputFile.absolutePath,
                        watermarkBitmap,
                        watermarkPosition,
                        options
                    )
                    
                    runOnUiThread {
                        if (success && outputFile.exists() && outputFile.length() > 0) {
                            if (deleteOriginal) {
                                inputFile.delete()
                            }
                            result.success(outputFile.absolutePath)
                        } else {
                            Log.e("MediaPickerPlus", "Video watermarking failed")
                            result.error("VIDEO_PROCESSING_ERROR", "FFmpeg video processing failed", null)
                        }
                    }
                }.start()
            } else {
                val retriever = MediaMetadataRetriever()
                var videoWidth = 0
                var videoHeight = 0
                var rotation = 0
                try {
                    retriever.setDataSource(videoPath)
                    videoWidth = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toInt() ?: 0
                    videoHeight = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toInt() ?: 0
                    rotation = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toInt() ?: 0
                } finally {
                    retriever.release()
                }

                val (effectiveWidth, effectiveHeight) = if (rotation == 90 || rotation == 270) {
                    Pair(videoHeight, videoWidth)
                } else {
                    Pair(videoWidth, videoHeight)
                }

                val maxWidth = options["maxWidth"] as? Int ?: effectiveWidth
                val maxHeight = options["maxHeight"] as? Int ?: effectiveHeight
                val cropInfo = applyCropToVideo(effectiveWidth, effectiveHeight, options)
                val baseWidth = cropInfo?.width ?: effectiveWidth
                val baseHeight = cropInfo?.height ?: effectiveHeight
                val (targetWidth, targetHeight) = calculateTargetDimensions(baseWidth, baseHeight, maxWidth, maxHeight)
                val targetBitrate = options["targetBitrate"] as? Int ?: options["videoBitrate"] as? Int

                val needsProcessing = cropInfo != null ||
                    targetWidth != baseWidth ||
                    targetHeight != baseHeight ||
                    targetBitrate != null

                if (!needsProcessing) {
                    result.success(videoPath)
                    return
                }

                Thread {
                    val success = processVideoWithoutWatermark(
                        videoPath,
                        outputFile.absolutePath,
                        effectiveWidth,
                        effectiveHeight,
                        rotation,
                        options
                    )
                    runOnUiThread {
                        if (success && outputFile.exists() && outputFile.length() > 0) {
                            if (deleteOriginal) {
                                inputFile.delete()
                            }
                            result.success(outputFile.absolutePath)
                        } else {
                            result.error("VIDEO_PROCESSING_ERROR", "FFmpeg video processing failed", null)
                        }
                    }
                }.start()
            }

        } catch (e: Exception) {
            Log.e("MediaPickerPlus", "Error setting up video processing: ${e.message}", e)
            result.error("VIDEO_PROCESSING_ERROR", "Error setting up video processing: ${e.message}", null)
        }
    }
    
    private fun getWatermarkPosition(position: String, videoWidth: Int, videoHeight: Int, fontSize: Int): Pair<String, String> {
        val margin = 20
        return when (position) {
            "topLeft" -> Pair("$margin", "$margin")
            "topRight" -> Pair("w-tw-$margin", "$margin")
            "bottomLeft" -> Pair("$margin", "h-th-$margin")
            "bottomRight" -> Pair("w-tw-$margin", "h-th-$margin")
            "center" -> Pair("(w-tw)/2", "(h-th)/2")
            else -> Pair("w-tw-$margin", "h-th-$margin") // Default to bottomRight
        }
    }

    private fun compressVideo(inputPath: String, outputPath: String?, options: HashMap<String, Any>, result: Result) {
        try {
            // Check if input file exists
            val inputFile = File(inputPath)
            if (!inputFile.exists()) {
                result.error("INVALID_VIDEO", "Input video file does not exist", null)
                return
            }
            
            // Generate output path if not provided
            val finalOutputPath = outputPath ?: run {
                val cacheDir = context.cacheDir
                val timestamp = System.currentTimeMillis()
                File(cacheDir, "compressed_video_$timestamp.mp4").absolutePath
            }
            
            val outputFile = File(finalOutputPath)
            
            // Remove existing output file if it exists
            if (outputFile.exists()) {
                outputFile.delete()
            }
            
            // Parse compression options
            val targetBitrate = options["targetBitrate"] as? Int ?: 1500000 // 1.5 Mbps default
            val targetWidth = options["targetWidth"] as? Int ?: 854
            val targetHeight = options["targetHeight"] as? Int ?: 480
            val deleteOriginal = options["deleteOriginalFile"] as? Boolean ?: false
            
            // Use MediaMetadataRetriever to get video info
            val retriever = MediaMetadataRetriever()
            retriever.setDataSource(inputPath)
            
            val originalWidth = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull() ?: targetWidth
            val originalHeight = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull() ?: targetHeight
            val rotation = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
            val duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0L
            
            retriever.release()
            
            // Account for video rotation - swap dimensions for 90/270 degree rotation
            // FFmpeg autorotate will rotate the frames, so we need to calculate dimensions based on the displayed orientation
            val effectiveWidth = if (rotation == 90 || rotation == 270) originalHeight else originalWidth
            val effectiveHeight = if (rotation == 90 || rotation == 270) originalWidth else originalHeight
            
            // Calculate actual output dimensions maintaining aspect ratio
            val aspectRatio = effectiveWidth.toFloat() / effectiveHeight.toFloat()
            val actualWidth: Int
            val actualHeight: Int
            
            if (effectiveWidth > effectiveHeight) {
                actualWidth = minOf(targetWidth, effectiveWidth)
                actualHeight = (actualWidth / aspectRatio).toInt()
            } else {
                actualHeight = minOf(targetHeight, effectiveHeight)
                actualWidth = (actualHeight * aspectRatio).toInt()
            }
            
            // Ensure dimensions are even numbers (required for some codecs)
            val evenWidth = if (actualWidth % 2 == 0) actualWidth else actualWidth - 1
            val evenHeight = if (actualHeight % 2 == 0) actualHeight else actualHeight - 1
            
            // Use MediaMuxer and MediaCodec for compression
            Thread {
                try {
                    val success = compressVideoWithMediaCodec(
                        inputPath,
                        finalOutputPath,
                        evenWidth,
                        evenHeight,
                        targetBitrate
                    )
                    
                    runOnUiThread {
                        if (success) {
                            if (deleteOriginal) {
                                inputFile.delete()
                            }
                            result.success(finalOutputPath)
                        } else {
                            result.error("COMPRESSION_FAILED", "Video compression failed", null)
                        }
                    }
                } catch (e: Exception) {
                    runOnUiThread {
                        result.error("COMPRESSION_ERROR", "Error during video compression: ${e.message}", null)
                    }
                }
            }.start()
            
        } catch (e: Exception) {
            result.error("COMPRESSION_ERROR", "Error setting up video compression: ${e.message}", null)
        }
    }
    
    private fun compressVideoWithMediaCodec(
        inputPath: String,
        outputPath: String,
        targetWidth: Int,
        targetHeight: Int,
        targetBitrate: Int
    ): Boolean {
        return try {
            val inputVideo = "\"$inputPath\""
            val output = "\"$outputPath\""
            val scaleFilter = "scale=$targetWidth:$targetHeight"
            val command = "-i $inputVideo -vf $scaleFilter -b:v $targetBitrate -c:a copy -c:v mpeg4 -q:v 5 -y $output"

            val latch = CountDownLatch(1)
            var success = false
            var errorMessage = ""

            val session = FFmpegKit.executeAsync(command,
                { session ->
                    val returnCode = session.returnCode
                    if (ReturnCode.isSuccess(returnCode)) {
                        success = true
                    } else {
                        errorMessage = "FFmpeg compression failed with code: $returnCode"
                    }
                    latch.countDown()
                },
                { log ->
                    Log.d("MediaPickerPlus", "FFmpeg log: ${log.message}")
                },
                { statistics ->
                    Log.d("MediaPickerPlus", "FFmpeg statistics: time=${statistics.time}ms, size=${statistics.size}")
                }
            )

            val completed = latch.await(10, TimeUnit.MINUTES)
            if (!completed) {
                session.cancel()
                return false
            }

            if (!success) {
                Log.e("MediaPickerPlus", errorMessage)
                return false
            }

            val outputFile = File(outputPath)
            outputFile.exists() && outputFile.length() > 0L
        } catch (e: Exception) {
            Log.e("MediaPickerPlus", "Error in video compression: ${e.message}", e)
            false
        }
    }
    
    private fun runOnUiThread(action: () -> Unit) {
        Handler(Looper.getMainLooper()).post(action)
    }
}
