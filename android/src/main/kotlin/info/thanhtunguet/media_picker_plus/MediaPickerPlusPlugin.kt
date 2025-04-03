package info.thanhtunguet.media_picker_plus

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
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
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.*

class MediaPickerPlusPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener, PluginRegistry.RequestPermissionsResultListener {
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
  private val REQUEST_CAMERA_PERMISSION = 2001
  private val REQUEST_GALLERY_PERMISSION = 2002

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.example.media_picker_plus")
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
                else -> result.error("INVALID_TYPE", "Invalid media type specified", null)
              }
            } else {
              requestGalleryPermission()
            }
          }
          "camera" -> {
            if (hasCameraPermission()) {
              when (type) {
                "image" -> capturePhoto()
                "video" -> recordVideo()
                else -> result.error("INVALID_TYPE", "Invalid media type specified", null)
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
            if (options.containsKey("width") && options.containsKey("height")) {
              val width = options["width"] as Int?
              val height = options["height"] as Int?
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
                intent.putExtra(MediaStore.EXTRA_VIDEO_QUALITY, if (bitrate > 8000000) 1 else 0)
              }
            }

            if (options.containsKey("width") && options.containsKey("height")) {
              val width = options["width"] as Int?
              val height = options["height"] as Int?
              if (width != null && height != null) {
                intent.putExtra(MediaStore.EXTRA_SIZE_LIMIT, width * height)
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
    return cursor?.use {
      val columnIndex = it.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)
      it.moveToFirst()
      it.getString(columnIndex)
    }
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (resultCode == Activity.RESULT_OK) {
      when (requestCode) {
        REQUEST_IMAGE_CAPTURE, REQUEST_VIDEO_CAPTURE -> {
          currentMediaPath?.let { path ->
            pendingResult?.success(path)
            pendingResult = null
            currentMediaPath = null
          }
          return true
        }
        REQUEST_PICK_IMAGE, REQUEST_PICK_VIDEO -> {
          data?.data?.let { uri ->
            val filePath = getFilePathFromUri(uri)
            pendingResult?.success(filePath)
            pendingResult = null
          } ?: run {
            pendingResult?.error("NO_FILE", "No file was selected", null)
          }
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

  override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
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
    }
    return false
  }
}