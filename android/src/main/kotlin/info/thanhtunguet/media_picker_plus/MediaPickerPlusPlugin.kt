package info.thanhtunguet.media_picker_plus

import android.Manifest
import android.app.Activity
import android.content.ContentResolver
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
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.*

// Import Mp4Composer library
import com.daasuu.mp4compose.composer.Mp4Composer
import com.daasuu.mp4compose.filter.GlWatermarkFilter
import androidx.core.graphics.scale
import androidx.core.graphics.createBitmap

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
                return when (position.toLowerCase()) {
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
        when (call.method) {
            "pickMedia" -> {
                val source = call.argument<String>("source")
                val type = call.argument<String>("type")
                mediaOptions = call.argument<HashMap<String, Any>>("options")

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

                    // Set quality and resolution if specified
                    mediaOptions?.let { options ->
                        if (options.containsKey("maxWidth") && options.containsKey("maxHeight")) {
                            val width = options["maxWidth"] as Int?
                            val height = options["maxHeight"] as Int?
                            if (width != null && height != null) {
                                intent.putExtra(MediaStore.EXTRA_SIZE_LIMIT, width * height)
                            }
                        }
                    }

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

                    // Set quality and resolution if specified
                    mediaOptions?.let { options ->
                        if (options.containsKey("videoBitrate")) {
                            val bitrate = options["videoBitrate"] as Int?
                            if (bitrate != null) {
                                intent.putExtra(
                                    MediaStore.EXTRA_VIDEO_QUALITY,
                                    if (bitrate > 1500000) 1 else 0
                                )
                            }
                        }

                        if (options.containsKey("maxWidth") && options.containsKey("maxHeight")) {
                            val width = options["maxWidth"] as Int?
                            val height = options["maxHeight"] as Int?
                            if (width != null && height != null) {
                                intent.putExtra(MediaStore.EXTRA_SIZE_LIMIT, width * height)
                            }
                        }
                        
                        if (options.containsKey("maxDuration")) {
                            val maxDuration = options["maxDuration"] as Int?
                            if (maxDuration != null) {
                                intent.putExtra(MediaStore.EXTRA_DURATION_LIMIT, maxDuration)
                            }
                        }
                    }

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
        // Content URI path resolution
        val projection = arrayOf(MediaStore.MediaColumns.DATA)
        val cursor = context.contentResolver.query(uri, projection, null, null, null)
        cursor?.use {
            if (it.moveToFirst()) {
                val columnIndex = it.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)
                return it.getString(columnIndex)
            }
        }

        // If content resolver fails, try direct file URI path
        if (uri.scheme == "file") {
            return uri.path
        }

        // Last resort: Copy file to a temporary location
        return copyUriToTempFile(uri)
    }

    private fun copyUriToTempFile(uri: Uri): String? {
        try {
            val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
            val storageDir = context.getExternalFilesDir(Environment.DIRECTORY_PICTURES)

            // Determine file extension
            val contentResolver = context.contentResolver
            val mimeType = contentResolver.getType(uri)
            val extension = when {
                mimeType?.contains("image") == true -> ".jpg"
                mimeType?.contains("video") == true -> ".mp4"
                else -> ".tmp"
            }

            val file = File.createTempFile("MEDIA_${timeStamp}", extension, storageDir)
            contentResolver.openInputStream(uri)?.use { input ->
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
            // Create bitmap from file
            var bitmap = android.graphics.BitmapFactory.decodeFile(sourcePath)

            // Process image size if required
            if (options.containsKey("maxWidth") && options.containsKey("maxHeight")) {
                val maxWidth = options["maxWidth"] as? Int ?: 0
                val maxHeight = options["maxHeight"] as? Int ?: 0

                if (maxWidth > 0 && maxHeight > 0) {
                    val width = bitmap.width
                    val height = bitmap.height

                    val widthRatio = maxWidth.toFloat() / width
                    val heightRatio = maxHeight.toFloat() / height
                    val ratio = minOf(widthRatio, heightRatio)

                    // Only resize if the image is larger than the specified dimensions
                    if (ratio < 1) {
                        val newWidth = (width * ratio).toInt()
                        val newHeight = (height * ratio).toInt()

                        bitmap = bitmap.scale(newWidth, newHeight)
                    }
                }
            }

            // Add watermark if specified
            if (options.containsKey("watermark")) {
                val watermarkText = options["watermark"] as? String
                if (!watermarkText.isNullOrEmpty()) {
                    val fontSize = options["watermarkFontSize"] as? Float ?: 24f

                    // Fixed: Convert to string or use default
                    val positionObj = options["watermarkPosition"]
                    val position = if (positionObj is String) {
                        positionObj
                    } else {
                        "bottomRight" // Default position
                    }

                    bitmap = addWatermarkToBitmap(bitmap, watermarkText, fontSize, position)
                }
            }

            // Determine quality - handle both Int and Boolean
            var quality = 85 // Default medium quality
            if (options.containsKey("imageQuality")) {
                val imageQuality = when (val imageQualityValue = options["imageQuality"]) {
                    is Int -> imageQualityValue
                    is Double -> imageQualityValue.toInt()
                    is Boolean -> if (imageQualityValue) 90 else 75
                    else -> 85 // Default medium quality
                }

                quality = when {
                    imageQuality >= 90 -> 90 // High
                    imageQuality >= 80 -> 85 // Medium
                    else -> 75 // Low
                }
            }

            // Create a new file for the processed image
            val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
            val fileName = "IMG_PROCESSED_$timeStamp.jpg"
            val storageDir = context.getExternalFilesDir(Environment.DIRECTORY_PICTURES)
            val outputFile = File(storageDir, fileName)

            // Save the bitmap to the new file
            FileOutputStream(outputFile).use { out ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, quality, out)
            }

            // Delete the original file if it was temporary
            val sourceFile = File(sourcePath)
            if (sourceFile.name.contains("IMG_") && sourceFile.parentFile == storageDir) {
                sourceFile.delete()
            }

            return outputFile.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            return sourcePath // Return original path if processing fails
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

        // Configure the paint
        val paint = Paint().apply {
            color = Color.WHITE
            alpha = 200 // 80% opacity
            textSize = fontSize
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            isAntiAlias = true
        }

        // Add stroke to make text more visible on different backgrounds
        val strokePaint = Paint(paint).apply {
            style = Paint.Style.STROKE
            strokeWidth = 2f
            color = Color.BLACK
        }

        // Measure text dimensions
        val bounds = Rect()
        paint.getTextBounds(text, 0, text.length, bounds)
        val textWidth = bounds.width()
        val textHeight = bounds.height()

        // Calculate position for watermark
        val padding = 20f

        // Convert string position to enum
        val position = if (positionStr == "auto") {
            // Use longer edge
            if (bitmap.width > bitmap.height) {
                // Landscape, place on the right side
                WatermarkPosition.BOTTOM_RIGHT
            } else {
                // Portrait, place on the bottom
                WatermarkPosition.BOTTOM_CENTER
            }
        } else {
            WatermarkPosition.fromString(positionStr)
        }

        val x: Float
        val y: Float

        // Determine coordinates based on position
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

        // Draw the text outline first (for better visibility)
        canvas.drawText(text, x, y, strokePaint)

        // Draw the actual text
        canvas.drawText(text, x, y, paint)

        return result
    }

    private fun processVideo(sourcePath: String): String {
        val options = mediaOptions ?: return sourcePath

        // Only process if watermark is needed
        if (!options.containsKey("watermark")) {
            return sourcePath
        }

        val watermarkText = options["watermark"] as? String
        if (watermarkText.isNullOrEmpty()) {
            return sourcePath
        }

        try {
            // Create a new output video file
            val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
            val videoFileName = "VID_PROCESSED_$timeStamp.mp4"
            val storageDir = context.getExternalFilesDir(Environment.DIRECTORY_PICTURES)
            val outputVideoFile = File(storageDir, videoFileName)

            // Get watermark parameters
            val fontSize = options["watermarkFontSize"] as? Float ?: 24f
            val positionObj = options["watermarkPosition"]
            val position = if (positionObj is String) positionObj else "bottomRight"

            // Create bitmap with watermark text
            val watermarkBitmap = createWatermarkBitmap(watermarkText, fontSize)

            // Use Mp4Composer to add watermark
            val success = watermarkVideoWithMp4Composer(
                sourcePath,
                outputVideoFile.absolutePath,
                watermarkBitmap,
                position
            )

            return if (success) outputVideoFile.absolutePath else sourcePath

        } catch (e: Exception) {
            Log.e("MediaPickerPlus", "Error processing video: ${e.message}", e)
            return sourcePath // Return original path if processing fails
        }
    }

    private fun createWatermarkBitmap(text: String, fontSize: Float): Bitmap {
        val paint = Paint().apply {
            color = Color.WHITE
            alpha = 200 // 80% opacity
            textSize = fontSize
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            isAntiAlias = true
        }

        // Measure text dimensions
        val bounds = Rect()
        paint.getTextBounds(text, 0, text.length, bounds)
        val textWidth = bounds.width()
        val textHeight = bounds.height()

        // Create bitmap for watermark with padding
        val padding = 20
        val watermarkBitmap = createBitmap(textWidth + padding * 2, textHeight + padding * 2)

        val canvas = Canvas(watermarkBitmap)

        // Draw text outline for better visibility on different backgrounds
        val strokePaint = Paint(paint).apply {
            style = Paint.Style.STROKE
            strokeWidth = 2f
            color = Color.BLACK
        }

        canvas.drawText(text, padding.toFloat(), textHeight + padding / 2f, strokePaint)
        canvas.drawText(text, padding.toFloat(), textHeight + padding / 2f, paint)

        return watermarkBitmap
    }

    private fun watermarkVideoWithMp4Composer(
        inputPath: String,
        outputPath: String,
        watermarkBitmap: Bitmap,
        position: String
    ): Boolean {
        var compositionCompleted = false

        try {
            // Get the position enum
            val positionEnum = WatermarkPosition.fromString(position)

            // Convert to GlWatermarkFilter position
            // Fix: Use the correct enum values available in the library
            val filterPosition = when (positionEnum) {
                WatermarkPosition.TOP_LEFT -> GlWatermarkFilter.Position.LEFT_TOP
                WatermarkPosition.TOP_CENTER -> GlWatermarkFilter.Position.LEFT_TOP
                WatermarkPosition.TOP_RIGHT -> GlWatermarkFilter.Position.RIGHT_TOP
                WatermarkPosition.MIDDLE_LEFT -> GlWatermarkFilter.Position.LEFT_BOTTOM // Approximation
                WatermarkPosition.CENTER -> GlWatermarkFilter.Position.RIGHT_BOTTOM // Approximation
                WatermarkPosition.MIDDLE_RIGHT -> GlWatermarkFilter.Position.RIGHT_TOP // Approximation
                WatermarkPosition.BOTTOM_LEFT -> GlWatermarkFilter.Position.LEFT_BOTTOM
                WatermarkPosition.BOTTOM_CENTER -> GlWatermarkFilter.Position.RIGHT_BOTTOM // Approximation
                WatermarkPosition.BOTTOM_RIGHT -> GlWatermarkFilter.Position.RIGHT_BOTTOM
            }

            // Create GlWatermarkFilter with the bitmap and position
            val watermarkFilter = GlWatermarkFilter(watermarkBitmap, filterPosition)

            // Use synchronous approach with CountDownLatch for simplicity
            val latch = java.util.concurrent.CountDownLatch(1)

            // Fix: Create Mp4Composer correctly and implement all required methods of the listener
            com.daasuu.mp4compose.composer.Mp4Composer(inputPath, outputPath)
                .filter(watermarkFilter)
                .listener(object : com.daasuu.mp4compose.composer.Mp4Composer.Listener {
                    override fun onProgress(progress: Double) {
                        Log.d("MediaPickerPlus", "Processing video: ${(progress * 100).toInt()}%")
                    }

                    override fun onCompleted() {
                        Log.d("MediaPickerPlus", "Video processing completed")
                        compositionCompleted = true
                        latch.countDown()
                    }

                    override fun onCanceled() {
                        Log.d("MediaPickerPlus", "Video processing canceled")
                        latch.countDown()
                    }

                    override fun onFailed(exception: Exception) {
                        Log.e("MediaPickerPlus", "Video processing failed", exception)
                        latch.countDown()
                    }

                    // Fix: Implement missing required method
                    override fun onCurrentWrittenVideoTime(time: Long) {
                        // This method is required but we don't need to do anything with it
                    }
                })
                .start()

            // Wait for the composition to finish (with timeout)
            latch.await(5, java.util.concurrent.TimeUnit.MINUTES)

            return compositionCompleted

        } catch (e: Exception) {
            Log.e("MediaPickerPlus", "Error in Mp4Composer: ${e.message}", e)
            return false
        }
    }

    private fun pickFile(allowedExtensions: List<String>?) {
        val activity = activity ?: return
        
        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            type = "*/*"
            addCategory(Intent.CATEGORY_OPENABLE)
            
            // Set MIME types based on extensions
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
            
            // Set MIME types based on extensions
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
                        // Process image (resize, add watermark, etc.)
                        val processedPath = processImage(path)
                        pendingResult?.success(processedPath)
                        pendingResult = null
                        currentMediaPath = null
                    }
                    return true
                }

                REQUEST_VIDEO_CAPTURE -> {
                    currentMediaPath?.let { path ->
                        // Process video (add watermark if needed)
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
                            // Process the picked image
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
                            // Process the picked video
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
                        // Multiple files selected
                        for (i in 0 until clipData.itemCount) {
                            val uri = clipData.getItemAt(i).uri
                            val filePath = getFilePathFromUri(uri)
                            filePath?.let { filePaths.add(it) }
                        }
                    } ?: data?.data?.let { uri ->
                        // Single file selected
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
                        // Multiple files selected
                        for (i in 0 until clipData.itemCount) {
                            val uri = clipData.getItemAt(i).uri
                            val filePath = getFilePathFromUri(uri)
                            filePath?.let { path ->
                                // Process based on media type
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
                        // Single file selected
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