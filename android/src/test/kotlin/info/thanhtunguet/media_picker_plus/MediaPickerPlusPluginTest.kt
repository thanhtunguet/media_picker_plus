package info.thanhtunguet.media_picker_plus

import kotlin.test.Test
import kotlin.test.assertEquals

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
}
