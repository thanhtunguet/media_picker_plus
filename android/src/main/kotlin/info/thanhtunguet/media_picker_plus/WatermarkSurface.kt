package info.thanhtunguet.media_picker_plus

import android.graphics.Bitmap
import android.graphics.Color
import android.opengl.EGL14
import android.opengl.EGLConfig
import android.opengl.EGLDisplay
import android.view.Surface
import androidx.core.graphics.scale

class WatermarkSurface(
    private val inputSurface: Surface,
    private val watermarkBitmap: Bitmap,
    private val width: Int,
    private val height: Int
) {
    val surface: Surface

    init {
        val eglDisplay = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
        val eglConfig = chooseEglConfig(eglDisplay)
        val eglContext = EGL14.eglCreateContext(eglDisplay, eglConfig, EGL14.EGL_NO_CONTEXT, intArrayOf(
            EGL14.EGL_CONTEXT_CLIENT_VERSION, 2,
            EGL14.EGL_NONE
        ), 0)

        val eglSurface = EGL14.eglCreateWindowSurface(eglDisplay, eglConfig, inputSurface, null, 0)
        EGL14.eglMakeCurrent(eglDisplay, eglSurface, eglSurface, eglContext)

        // Create watermark texture, render frame, etc. (simplified)
        val canvas = inputSurface.lockCanvas(null)
        canvas.drawColor(Color.BLACK) // Clear background
        val resized = watermarkBitmap.scale(200, 80, false)
        canvas.drawBitmap(resized, width - 220f, height - 100f, null)
        inputSurface.unlockCanvasAndPost(canvas)

        surface = inputSurface
    }

    fun release() {
        surface.release()
    }

    private fun chooseEglConfig(display: EGLDisplay): EGLConfig {
        val attribList = intArrayOf(
            EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
            EGL14.EGL_SURFACE_TYPE, EGL14.EGL_WINDOW_BIT,
            EGL14.EGL_RED_SIZE, 8,
            EGL14.EGL_GREEN_SIZE, 8,
            EGL14.EGL_BLUE_SIZE, 8,
            EGL14.EGL_ALPHA_SIZE, 8,
            EGL14.EGL_NONE
        )
        val configs = arrayOfNulls<EGLConfig>(1)
        val numConfigs = IntArray(1)
        EGL14.eglChooseConfig(display, attribList, 0, configs, 0, 1, numConfigs, 0)
        return configs[0]!!
    }
}
