package info.thanhtunguet.media_picker_plus

import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.test.assertNotEquals
import kotlin.test.Test
import android.content.Context
import org.mockito.Mockito

/*
 * This demonstrates a simple unit test of the Kotlin portion of this plugin's implementation.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * you can run them directly from IDEs that support JUnit such as Android Studio.
 */

internal class MediaPickerPlusPluginTest {
  @Test
  fun applyVideo_withoutWatermark_shouldCreateNewOutputWhenResizeRequested() {
    val plugin = MediaPickerPlusPlugin()

    val tempDir = createTempDir()
    val inputFile = File.createTempFile("input", ".mp4", tempDir)

    val context = Mockito.mock(Context::class.java)
    Mockito.`when`(context.cacheDir).thenReturn(tempDir)
    val contextField = plugin.javaClass.getDeclaredField("context")
    contextField.isAccessible = true
    contextField.set(plugin, context)

    val result = CapturingResult()
    val method = plugin.javaClass.getDeclaredMethod(
      "applyVideo",
      String::class.java,
      HashMap::class.java,
      MethodChannel.Result::class.java
    )
    method.isAccessible = true

    val options = hashMapOf<String, Any>(
      "maxWidth" to 320,
      "maxHeight" to 240
    )

    method.invoke(plugin, inputFile.absolutePath, options, result)

    assertNotEquals(inputFile.absolutePath, result.successValue as String)
  }
}

private class CapturingResult : MethodChannel.Result {
  var successValue: Any? = null
  var errorCode: String? = null
  var errorMessage: String? = null

  override fun success(result: Any?) {
    successValue = result
  }

  override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
    this.errorCode = errorCode
    this.errorMessage = errorMessage
  }

  override fun notImplemented() {
    errorCode = "not_implemented"
  }
}
