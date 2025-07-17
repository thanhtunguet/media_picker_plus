package info.thanhtunguet.media_picker_plus

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.Typeface
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import android.media.MediaMetadataRetriever
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
import kotlin.math.min

class MediaPickerPlusPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener, PluginRegistry.RequestPermissionsResultListener {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var pendingResult: Result? = null
    private var currentMediaPath: String? = null
    private var mediaOptions: HashMap<String, Any>? = null

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

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "info.thanhtunguet.media_picker_plus"
        )
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
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
            "pickMedia" -> {
                val source = call.argument<String>("source")
                val type = call.argument<String>("type")
                mediaOptions = call.argument<HashMap<String, Any>>("options")
                
                Log.d("MediaPickerPlus", "pickMedia - source: $source, type: $type")
                Log.d("MediaPickerPlus", "pickMedia - mediaOptions: $mediaOptions")

                pendingResult = result

                when (source) {
                    "gallery" -> {
                        if (hasGalleryPermission()) {
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
                            requestGalleryPermission()
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
                            requestCameraPermission()
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
                pickMultipleMedia(source, type)
            }

            else -> result.notImplemented()
        }
    }

    private fun createMediaFile(isImage: Boolean): File? {
        try {
            val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
            val fileName = if (isImage) "IMG_${timeStamp}" else "VID_${timeStamp}"
            val storageDir = context.getExternalFilesDir(Environment.DIRECTORY_PICTURES)
            val extension = if (isImage) ".jpg" else ".mp4"
            val file = File.createTempFile(fileName, extension, storageDir)
            currentMediaPath = file.absolutePath
            return file
        } catch (e: IOException) {
            e.printStackTrace()
        }
        return null
    }

    private fun capturePhoto() {
        val activity = activity ?: return

        Intent(MediaStore.ACTION_IMAGE_CAPTURE).also { intent ->
            intent.resolveActivity(activity.packageManager)?.also {
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

        val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
        activity.startActivityForResult(intent, REQUEST_PICK_IMAGE)
    }

    private fun pickVideoFromGallery() {
        val activity = activity ?: return

        val intent = Intent(Intent.ACTION_PICK, MediaStore.Video.Media.EXTERNAL_CONTENT_URI)
        activity.startActivityForResult(intent, REQUEST_PICK_VIDEO)
    }

    private fun hasCameraPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestCameraPermission() {
        activity?.let {
            ActivityCompat.requestPermissions(
                it,
                arrayOf(Manifest.permission.CAMERA),
                REQUEST_CAMERA_PERMISSION
            )
        }
    }

    private fun hasMicrophonePermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestMicrophonePermission() {
        activity?.let {
            ActivityCompat.requestPermissions(
                it,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                REQUEST_MICROPHONE_PERMISSION
            )
        }
    }

    private fun hasGalleryPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.READ_MEDIA_IMAGES
            ) == PackageManager.PERMISSION_GRANTED &&
                    ContextCompat.checkSelfPermission(
                        context,
                        Manifest.permission.READ_MEDIA_VIDEO
                    ) == PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.READ_EXTERNAL_STORAGE
            ) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestGalleryPermission() {
        activity?.let {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                ActivityCompat.requestPermissions(
                    it,
                    arrayOf(
                        Manifest.permission.READ_MEDIA_IMAGES,
                        Manifest.permission.READ_MEDIA_VIDEO
                    ),
                    REQUEST_GALLERY_PERMISSION
                )
            } else {
                ActivityCompat.requestPermissions(
                    it,
                    arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE),
                    REQUEST_GALLERY_PERMISSION
                )
            }
        }
    }

    private fun getFilePathFromUri(uri: Uri): String? {
        val projection = arrayOf(MediaStore.MediaColumns.DATA)
        val cursor = context.contentResolver.query(uri, projection, null, null, null)
        cursor?.use {
            if (it.moveToFirst()) {
                val columnIndex = it.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)
                return it.getString(columnIndex)
            }
        }
        if (uri.scheme == "file") {
            return uri.path
        }
        return copyUriToTempFile(uri)
    }

    private fun copyUriToTempFile(uri: Uri): String? {
        try {
            val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
            val storageDir = context.getExternalFilesDir(Environment.DIRECTORY_PICTURES)
            val mimeType = context.contentResolver.getType(uri)
            val extension = when {
                mimeType?.contains("image") == true -> ".jpg"
                mimeType?.contains("video") == true -> ".mp4"
                else -> ".tmp"
            }
            val file = File.createTempFile("MEDIA_${timeStamp}", extension, storageDir)
            context.contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(file).use { output ->
                    input.copyTo(output)
                }
            }
            return file.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }

    private fun processImage(sourcePath: String): String {
        val options = mediaOptions ?: return sourcePath
        try {
            var bitmap = android.graphics.BitmapFactory.decodeFile(sourcePath)
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
                    val fontSize = (options["watermarkFontSize"] as? Double)?.toFloat() ?: 24f
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
            val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
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
        val paint = Paint().apply {
            color = Color.WHITE
            alpha = 200
            textSize = fontSize
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            isAntiAlias = true
        }
        val strokePaint = Paint(paint).apply {
            style = Paint.Style.STROKE
            strokeWidth = 2f
            color = Color.BLACK
        }
        val bounds = Rect()
        paint.getTextBounds(text, 0, text.length, bounds)
        val textWidth = bounds.width()
        val textHeight = bounds.height()
        val padding = 20f
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
                x = padding
                y = textHeight + padding
            }
            WatermarkPosition.TOP_CENTER -> {
                x = (bitmap.width - textWidth) / 2f
                y = textHeight + padding
            }
            WatermarkPosition.TOP_RIGHT -> {
                x = bitmap.width - textWidth - padding
                y = textHeight + padding
            }
            WatermarkPosition.MIDDLE_LEFT -> {
                x = padding
                y = bitmap.height / 2f + textHeight / 2f
            }
            WatermarkPosition.CENTER -> {
                x = (bitmap.width - textWidth) / 2f
                y = bitmap.height / 2f + textHeight / 2f
            }
            WatermarkPosition.MIDDLE_RIGHT -> {
                x = bitmap.width - textWidth - padding
                y = bitmap.height / 2f + textHeight / 2f
            }
            WatermarkPosition.BOTTOM_LEFT -> {
                x = padding
                y = bitmap.height - padding
            }
            WatermarkPosition.BOTTOM_CENTER -> {
                x = (bitmap.width - textWidth) / 2f
                y = bitmap.height - padding
            }
            WatermarkPosition.BOTTOM_RIGHT -> {
                x = bitmap.width - textWidth - padding
                y = bitmap.height - padding
            }
        }
        canvas.drawText(text, x, y, strokePaint)
        canvas.drawText(text, x, y, paint)
        return result
    }

    private fun processVideo(sourcePath: String): String {
        Log.d("MediaPickerPlus", "processVideo called with sourcePath: $sourcePath")
        val options = mediaOptions
        Log.d("MediaPickerPlus", "mediaOptions: $options")
        
        if (options == null) {
            Log.d("MediaPickerPlus", "No media options found, returning original path")
            return sourcePath
        }
        
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
            val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
            val videoFileName = "VID_PROCESSED_$timeStamp.mp4"
            val storageDir = context.getExternalFilesDir(Environment.DIRECTORY_PICTURES)
            val outputVideoFile = File(storageDir, videoFileName)
            val fontSize = (options["watermarkFontSize"] as? Double)?.toFloat() ?: 48f  // Increased default size
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
                position
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
        
        val paint = Paint().apply {
            color = Color.WHITE
            alpha = 255  // Make it fully opaque for testing
            textSize = fontSize
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            isAntiAlias = true
        }
        val bounds = Rect()
        paint.getTextBounds(text, 0, text.length, bounds)
        val textWidth = bounds.width()
        val textHeight = bounds.height()
        val padding = 20
        
        Log.d("MediaPickerPlus", "Text dimensions: ${textWidth}x${textHeight}, padding: $padding")
        
        val watermarkBitmap = Bitmap.createBitmap(textWidth + padding * 2, textHeight + padding * 2, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(watermarkBitmap)
        
        // Add a semi-transparent background to make the watermark more visible
        val backgroundPaint = Paint().apply {
            color = Color.BLACK
            alpha = 128
        }
        canvas.drawRect(0f, 0f, watermarkBitmap.width.toFloat(), watermarkBitmap.height.toFloat(), backgroundPaint)
        
        val strokePaint = Paint(paint).apply {
            style = Paint.Style.STROKE
            strokeWidth = 3f  // Make stroke thicker
            color = Color.BLACK
        }
        canvas.drawText(text, padding.toFloat(), textHeight + padding / 2f, strokePaint)
        canvas.drawText(text, padding.toFloat(), textHeight + padding / 2f, paint)
        
        Log.d("MediaPickerPlus", "Watermark bitmap created: ${watermarkBitmap.width}x${watermarkBitmap.height}")
        return watermarkBitmap
    }

    private fun watermarkVideoWithNativeProcessing(
        inputPath: String,
        outputPath: String,
        watermarkBitmap: Bitmap,
        position: String
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
            
            // Process video using FFmpeg
            return processVideoWithFFmpeg(inputPath, outputPath, watermarkBitmap, position, width, height, duration, rotation)
            
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
        rotation: Int
    ): Boolean {
        return try {
            Log.d("MediaPickerPlus", "Processing video with FFmpeg")
            
            // Save watermark bitmap to temporary file
            val watermarkFile = File(context.cacheDir, "watermark_${System.currentTimeMillis()}.png")
            val watermarkOutputStream = FileOutputStream(watermarkFile)
            watermarkBitmap.compress(Bitmap.CompressFormat.PNG, 100, watermarkOutputStream)
            watermarkOutputStream.close()
            
            Log.d("MediaPickerPlus", "Watermark saved to: ${watermarkFile.absolutePath}")
            
            // Get options from mediaOptions
            val maxWidth = (mediaOptions?.get("maxWidth") as? Int) ?: videoWidth
            val maxHeight = (mediaOptions?.get("maxHeight") as? Int) ?: videoHeight
            
            Log.d("MediaPickerPlus", "Max dimensions: ${maxWidth}x${maxHeight}")
            
            // Calculate target dimensions (with aspect ratio preservation)
            val (targetWidth, targetHeight) = calculateTargetDimensions(videoWidth, videoHeight, maxWidth, maxHeight)
            
            Log.d("MediaPickerPlus", "Target dimensions: ${targetWidth}x${targetHeight}")
            
            // Calculate watermark position
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
                rotation
            )
            
            Log.d("MediaPickerPlus", "FFmpeg command: $command")
            
            // Execute FFmpeg command
            val latch = CountDownLatch(1)
            var success = false
            var errorMessage = ""
            
            val session = FFmpegKit.executeAsync(command,
                { session ->
                    val returnCode = session.returnCode
                    if (ReturnCode.isSuccess(returnCode)) {
                        Log.d("MediaPickerPlus", "FFmpeg processing completed successfully")
                        success = true
                    } else {
                        Log.e("MediaPickerPlus", "FFmpeg failed with return code: $returnCode")
                        errorMessage = "FFmpeg processing failed with code: $returnCode"
                    }
                    latch.countDown()
                },
                { log ->
                    Log.d("MediaPickerPlus", "FFmpeg log: ${log.message}")
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
        val padding = 20
        
        return when (position) {
            WatermarkPosition.TOP_LEFT -> Pair(padding, padding)
            WatermarkPosition.TOP_CENTER -> Pair((videoWidth - watermarkWidth) / 2, padding)
            WatermarkPosition.TOP_RIGHT -> Pair(videoWidth - watermarkWidth - padding, padding)
            WatermarkPosition.MIDDLE_LEFT -> Pair(padding, (videoHeight - watermarkHeight) / 2)
            WatermarkPosition.CENTER -> Pair((videoWidth - watermarkWidth) / 2, (videoHeight - watermarkHeight) / 2)
            WatermarkPosition.MIDDLE_RIGHT -> Pair(videoWidth - watermarkWidth - padding, (videoHeight - watermarkHeight) / 2)
            WatermarkPosition.BOTTOM_LEFT -> Pair(padding, videoHeight - watermarkHeight - padding)
            WatermarkPosition.BOTTOM_CENTER -> Pair((videoWidth - watermarkWidth) / 2, videoHeight - watermarkHeight - padding)
            WatermarkPosition.BOTTOM_RIGHT -> Pair(videoWidth - watermarkWidth - padding, videoHeight - watermarkHeight - padding)
        }
    }
    
    private fun buildFFmpegCommand(
        inputPath: String,
        outputPath: String,
        watermarkPath: String,
        watermarkX: Int,
        watermarkY: Int,
        targetWidth: Int,
        targetHeight: Int,
        rotation: Int
    ): String {
        val inputVideo = "\"$inputPath\""
        val watermarkImage = "\"$watermarkPath\""
        val output = "\"$outputPath\""
        
        // Build video scaling filter
        val scaleFilter = "scale=$targetWidth:$targetHeight"
        
        // Build rotation filter if needed
        val rotationFilter = when (rotation) {
            90 -> "transpose=1"
            180 -> "transpose=1,transpose=1"
            270 -> "transpose=2"
            else -> null
        }
        
        // Build overlay filter
        val overlayFilter = "overlay=$watermarkX:$watermarkY"
        
        // Combine filters
        val videoFilters = mutableListOf<String>()
        videoFilters.add(scaleFilter)
        if (rotationFilter != null) {
            videoFilters.add(rotationFilter)
        }
        
        val filterComplex = if (videoFilters.isEmpty()) {
            "[0:v][1:v]$overlayFilter"
        } else {
            "[0:v]${videoFilters.joinToString(",")}[scaled];[scaled][1:v]$overlayFilter"
        }
        
        // Build complete FFmpeg command
        return "-i $inputVideo -i $watermarkImage -filter_complex \"$filterComplex\" -c:a copy -c:v libx264 -preset fast -crf 23 -y $output"
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

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (resultCode == Activity.RESULT_OK) {
            when (requestCode) {
                REQUEST_IMAGE_CAPTURE -> {
                    currentMediaPath?.let { path ->
                        val processedPath = processImage(path)
                        pendingResult?.success(processedPath)
                        pendingResult = null
                        currentMediaPath = null
                    }
                    return true
                }
                REQUEST_VIDEO_CAPTURE -> {
                    currentMediaPath?.let { path ->
                        val processedPath = processVideo(path)
                        pendingResult?.success(processedPath)
                        pendingResult = null
                        currentMediaPath = null
                    }
                    return true
                }
                REQUEST_PICK_IMAGE -> {
                    data?.data?.let { uri ->
                        val filePath = getFilePathFromUri(uri)
                        filePath?.let { path ->
                            val processedPath = processImage(path)
                            pendingResult?.success(processedPath)
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
                REQUEST_PICK_VIDEO -> {
                    data?.data?.let { uri ->
                        val filePath = getFilePathFromUri(uri)
                        filePath?.let { path ->
                            val processedPath = processVideo(path)
                            pendingResult?.success(processedPath)
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
                    val filePaths = mutableListOf<String>()
                    data?.clipData?.let { clipData ->
                        for (i in 0 until clipData.itemCount) {
                            val uri = clipData.getItemAt(i).uri
                            val filePath = getFilePathFromUri(uri)
                            filePath?.let { filePaths.add(it) }
                        }
                    } ?: data?.data?.let { uri ->
                        val filePath = getFilePathFromUri(uri)
                        filePath?.let { filePaths.add(it) }
                    }
                    if (filePaths.isNotEmpty()) {
                        pendingResult?.success(filePaths)
                    } else {
                        pendingResult?.error("NO_FILE", "No files were selected", null)
                    }
                    pendingResult = null
                    return true
                }
                REQUEST_PICK_MULTIPLE_MEDIA -> {
                    val filePaths = mutableListOf<String>()
                    data?.clipData?.let { clipData ->
                        for (i in 0 until clipData.itemCount) {
                            val uri = clipData.getItemAt(i).uri
                            val filePath = getFilePathFromUri(uri)
                            filePath?.let { path ->
                                val processedPath = if (isImageFile(path)) {
                                    processImage(path)
                                } else if (isVideoFile(path)) {
                                    processVideo(path)
                                } else {
                                    path
                                }
                                filePaths.add(processedPath)
                            }
                        }
                    } ?: data?.data?.let { uri ->
                        val filePath = getFilePathFromUri(uri)
                        filePath?.let { path ->
                            val processedPath = if (isImageFile(path)) {
                                processImage(path)
                            } else if (isVideoFile(path)) {
                                processVideo(path)
                            } else {
                                path
                            }
                            filePaths.add(processedPath)
                        }
                    }
                    if (filePaths.isNotEmpty()) {
                        pendingResult?.success(filePaths)
                    } else {
                        pendingResult?.error("NO_FILE", "No media files were selected", null)
                    }
                    pendingResult = null
                    return true
                }
            }
        } else if (resultCode == Activity.RESULT_CANCELED) {
            pendingResult?.error("CANCELLED", "User cancelled the operation", null)
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
                    pendingResult?.success(true)
                } else {
                    pendingResult?.success(false)
                }
                return true
            }
            REQUEST_GALLERY_PERMISSION -> {
                if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                    pendingResult?.success(true)
                } else {
                    pendingResult?.success(false)
                }
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
}
