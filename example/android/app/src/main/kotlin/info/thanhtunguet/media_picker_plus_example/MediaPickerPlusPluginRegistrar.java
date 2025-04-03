package info.thanhtunguet.media_picker_plus;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;

/**
 * MediaPickerPlusPlugin
 */
public class MediaPickerPlusPlugin implements FlutterPlugin {
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        // Delegate to the Kotlin implementation
        new com.example.media_picker_plus.MediaPickerPlusPlugin().onAttachedToEngine(flutterPluginBinding);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        // No-op
    }
}