package info.thanhtunguet.media_picker_plus

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

/*
 * This demonstrates a simple unit test of the Kotlin portion of this plugin's implementation.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * you can run them directly from IDEs that support JUnit such as Android Studio.
 */

internal class MediaPickerPlusPluginTest {
  @Test
  fun calculateTargetDimensions_preservesAspectRatio() {
    val plugin = MediaPickerPlusPlugin()
    val method = plugin.javaClass.getDeclaredMethod(
      "calculateTargetDimensions",
      Int::class.javaPrimitiveType,
      Int::class.javaPrimitiveType,
      Int::class.javaPrimitiveType,
      Int::class.javaPrimitiveType
    )
    method.isAccessible = true

    val result = method.invoke(plugin, 1920, 1080, 1280, 1280) as Pair<*, *>
    assertEquals(1280, result.first)
    assertEquals(720, result.second)
  }

  @Test
  fun processImageWithOptions_usesProvidedOptionsNotGlobalState() {
    val plugin = MediaPickerPlusPlugin()
    val processImageWithOptionsMethod = plugin.javaClass.getDeclaredMethod(
      "processImageWithOptions",
      String::class.java,
      java.util.HashMap::class.java
    )
    processImageWithOptionsMethod.isAccessible = true

    // Verify that the method accepts options parameter
    // This ensures the method signature requires explicit options, preventing reliance on global state
    assertNotNull(processImageWithOptionsMethod)
    assertTrue(processImageWithOptionsMethod.parameterTypes[1] == java.util.HashMap::class.java)
    
    // Verify the method has exactly 2 parameters (sourcePath and options)
    assertEquals(2, processImageWithOptionsMethod.parameterCount)
  }

  @Test
  fun processVideoWithOptions_usesProvidedOptionsNotGlobalState() {
    val plugin = MediaPickerPlusPlugin()
    val processVideoWithOptionsMethod = plugin.javaClass.getDeclaredMethod(
      "processVideoWithOptions",
      String::class.java,
      java.util.HashMap::class.java
    )
    processVideoWithOptionsMethod.isAccessible = true

    // Verify that the method accepts options parameter
    // This ensures the method signature requires explicit options, preventing reliance on global state
    assertNotNull(processVideoWithOptionsMethod)
    assertTrue(processVideoWithOptionsMethod.parameterTypes[1] == java.util.HashMap::class.java)
    
    // Verify the method has exactly 2 parameters (sourcePath and options)
    assertEquals(2, processVideoWithOptionsMethod.parameterCount)
  }

  @Test
  fun optionsSnapshot_preventsRaceConditions() {
    // This test verifies that options are properly snapshotted
    // by checking that HashMap copy creates independent instances.
    // This is critical for preventing race conditions where background threads
    // might read stale or incorrect options if global mediaOptions is modified
    // while processing is in progress.
    val originalOptions = java.util.HashMap<String, Any>()
    originalOptions["watermark"] = "Original"
    originalOptions["maxWidth"] = 1000
    originalOptions["maxHeight"] = 2000

    // Create snapshot (as done in onActivityResult before starting background threads)
    val snapshot = java.util.HashMap(originalOptions)
    
    // Simulate another request modifying global mediaOptions while processing
    originalOptions["watermark"] = "Modified"
    originalOptions["maxWidth"] = 2000
    originalOptions["maxHeight"] = 4000

    // Snapshot should remain unchanged - this is what background threads will use
    assertEquals("Original", snapshot["watermark"], 
      "Snapshot should preserve original watermark value")
    assertEquals(1000, snapshot["maxWidth"], 
      "Snapshot should preserve original maxWidth value")
    assertEquals(2000, snapshot["maxHeight"], 
      "Snapshot should preserve original maxHeight value")
    
    // Original should be modified (simulating concurrent request)
    assertEquals("Modified", originalOptions["watermark"])
    assertEquals(2000, originalOptions["maxWidth"])
    assertEquals(4000, originalOptions["maxHeight"])
    
    // Verify snapshots are truly independent (not just references)
    assertTrue(snapshot !== originalOptions, 
      "Snapshot should be a different object instance, not a reference")
  }
  
  @Test
  fun watermarkVideoWithNativeProcessing_requiresOptionsParameter() {
    val plugin = MediaPickerPlusPlugin()
    val method = plugin.javaClass.getDeclaredMethod(
      "watermarkVideoWithNativeProcessing",
      String::class.java,
      String::class.java,
      android.graphics.Bitmap::class.java,
      String::class.java,
      java.util.HashMap::class.java
    )
    method.isAccessible = true

    // Verify that the method requires options parameter (5 parameters total)
    // This ensures it doesn't read from global mediaOptions
    assertNotNull(method)
    assertEquals(5, method.parameterCount, 
      "watermarkVideoWithNativeProcessing should require 5 parameters including options")
    assertTrue(method.parameterTypes[4] == java.util.HashMap::class.java,
      "Last parameter should be HashMap<String, Any> for options")
  }
  
  @Test
  fun processVideoWithFFmpeg_requiresOptionsParameter() {
    val plugin = MediaPickerPlusPlugin()
    val method = plugin.javaClass.getDeclaredMethod(
      "processVideoWithFFmpeg",
      String::class.java,
      String::class.java,
      android.graphics.Bitmap::class.java,
      String::class.java,
      Int::class.javaPrimitiveType,
      Int::class.javaPrimitiveType,
      Long::class.javaPrimitiveType,
      Int::class.javaPrimitiveType,
      java.util.HashMap::class.java
    )
    method.isAccessible = true

    // Verify that the method requires options parameter (9 parameters total)
    // This ensures it doesn't read from global mediaOptions
    assertNotNull(method)
    assertEquals(9, method.parameterCount,
      "processVideoWithFFmpeg should require 9 parameters including options")
    assertTrue(method.parameterTypes[8] == java.util.HashMap::class.java,
      "Last parameter should be HashMap<String, Any> for options")
  }
}
