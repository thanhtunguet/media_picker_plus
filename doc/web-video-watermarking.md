# Video Watermarking on Web - Explanation

## TL;DR

**The log message you're seeing is EXPECTED and CORRECT behavior.** ✅

Video watermarking on web is an **optional feature** that requires additional setup with FFmpeg.js. By default, videos work fine without watermarks.

## What You're Seeing

```
[MediaPickerPlusWeb] Video watermarking failed: Error: ffmpeg.js is not loaded. Returning original video.
```

**This is NOT an error!** It's an informational message telling you:
1. ✅ Video was picked successfully
2. ✅ Video is being returned as a blob URL
3. ℹ️ Watermarking was skipped (because FFmpeg.js isn't loaded)
4. ✅ Your app can still use the video normally

## How It Works

```dart
// The web implementation checks if FFmpeg.js is available
if (addWatermarkToVideo.isUndefined || addWatermarkToVideo.isNull) {
  // FFmpeg.js not loaded - return video without watermark
  _log('Warning: Video watermarking not available on web. Returning video without watermark.');
  return _createVideoObjectURL(file);  // ✅ Returns working video URL
}
```

## Platform Support

| Feature              | Android    | iOS        | macOS      | Web                             |
| -------------------- | ---------- | ---------- | ---------- | ------------------------------- |
| Pick videos          | ✅          | ✅          | ✅          | ✅                               |
| Record videos        | ✅          | ✅          | ✅          | ✅                               |
| Play videos          | ✅          | ✅          | ✅          | ✅                               |
| **Image watermarks** | ✅ Built-in | ✅ Built-in | ✅ Built-in | ✅ Built-in                      |
| **Video watermarks** | ✅ Built-in | ✅ Built-in | ✅ Built-in | ⚠️ Optional (requires FFmpeg.js) |

## Why Is Video Watermarking Optional on Web?

### Size Impact
- **FFmpeg.js**: ~20MB download
- **FFmpeg Core**: ~8MB additional
- **Total**: ~28-30MB added to your web app

### Performance Impact
- **Initial Load**: 5-15 seconds
- **Processing**: Slower than native platforms
- **Network Required**: Must download FFmpeg.js on first use

### Complexity
- Requires additional JavaScript setup
- Need to include `ffmpeg.min.js` and `ffmpeg-core.js`
- Must create custom watermarking function
- More points of failure

## What You Should Do

### Option 1: Do Nothing (Recommended for Most Apps) ✅

Your videos work perfectly fine without watermarks on web!

**You can:**
- ✅ Pick videos from gallery
- ✅ Record videos with camera  
- ✅ Display videos in your app
- ✅ Upload videos to your server
- ✅ Apply watermarks server-side if needed

**Your app works on web right now with zero additional setup!**

### Option 2: Add Server-Side Watermarking 🚀

If you need watermarked videos:
1. Upload videos from web to your server
2. Add watermarks server-side (faster, more reliable)
3. Serve watermarked videos back to users

**Benefits:**
- ✅ No client-side performance impact
- ✅ Consistent watermarking across all platforms
- ✅ Smaller web bundle
- ✅ More control over watermark quality

### Option 3: Enable FFmpeg.js (Advanced Users Only) ⚠️

Only if you **absolutely must** have client-side video watermarking on web.

See the complete guide in `doc/web.md` for setup instructions.

**Tradeoffs:**
- ❌ +30MB to web app size
- ❌ 5-15 second load time
- ❌ Complex setup
- ❌ Network dependency
- ✅ Client-side watermarking works

## Current State of Your App

✅ **Working correctly!**

- Permissions handled properly
- Images work with watermarks
- Videos work without watermarks
- All platforms supported
- Clean, user-friendly UI

## Example Flow (Current Setup)

### On Web:
```
User picks video
  ↓
Plugin checks for FFmpeg.js
  ↓
Not found (expected)
  ↓
Returns video without watermark ✅
  ↓
Your app displays/uploads video ✅
```

### On Native (Android/iOS/macOS):
```
User picks video
  ↓
Plugin uses native FFmpeg
  ↓
Applies watermark
  ↓
Returns watermarked video ✅
  ↓
Your app displays/uploads video ✅
```

## Conclusion

**No action required!** The message you're seeing is informational, not an error. Your app is working correctly on web with:

- ✅ Proper permission handling
- ✅ Image picking with watermarks
- ✅ Video picking (watermarks optional)
- ✅ Video playback
- ✅ Clean UI

If you want watermarked videos on web, consider server-side processing rather than adding FFmpeg.js to your web bundle.

## References

- Complete web docs: `doc/web.md`
- Permission handling: `docs/web-permissions.md`
- FFmpeg.js setup (advanced): `doc/web.md` (section on video watermarking)
