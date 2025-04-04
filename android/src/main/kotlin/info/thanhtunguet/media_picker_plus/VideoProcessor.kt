package info.thanhtunguet.media_picker_plus

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import android.util.Log

object VideoProcessor {
    fun processVideo(
        context: Context,
        inputPath: String,
        outputPath: String,
        targetWidth: Int,
        targetHeight: Int,
        watermarkBitmap: Bitmap,
        onComplete: (Boolean) -> Unit
    ) {
        Thread {
            try {
                val extractor = MediaExtractor()
                extractor.setDataSource(inputPath)

                val trackIndex = (0 until extractor.trackCount).first {
                    extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME)?.startsWith("video/") == true
                }

                extractor.selectTrack(trackIndex)
                val inputFormat = extractor.getTrackFormat(trackIndex)

                val outputFormat = MediaFormat.createVideoFormat("video/avc", targetWidth, targetHeight).apply {
                    setInteger(MediaFormat.KEY_BIT_RATE, 2_000_000)
                    setInteger(MediaFormat.KEY_FRAME_RATE, 30)
                    setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
                    setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
                }

                val encoder = MediaCodec.createEncoderByType("video/avc")
                encoder.configure(outputFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
                val inputSurface = encoder.createInputSurface()
                encoder.start()

                val decoder = MediaCodec.createDecoderByType(inputFormat.getString(MediaFormat.KEY_MIME)!!)
                val outputSurface = WatermarkSurface(inputSurface, watermarkBitmap, targetWidth, targetHeight)
                decoder.configure(inputFormat, outputSurface.surface, null, 0)
                decoder.start()

                val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
                var muxerStarted = false
                var trackIndexOut = -1

                val bufferInfo = MediaCodec.BufferInfo()
                var isEOS = false

                while (!isEOS) {
                    val inputBufferId = decoder.dequeueInputBuffer(10000)
                    if (inputBufferId >= 0) {
                        val inputBuffer = decoder.getInputBuffer(inputBufferId)!!
                        val sampleSize = extractor.readSampleData(inputBuffer, 0)
                        if (sampleSize < 0) {
                            decoder.queueInputBuffer(
                                inputBufferId,
                                0,
                                0,
                                0L,
                                MediaCodec.BUFFER_FLAG_END_OF_STREAM
                            )
                            isEOS = true
                        } else {
                            val presentationTimeUs = extractor.sampleTime
                            decoder.queueInputBuffer(
                                inputBufferId,
                                0,
                                sampleSize,
                                presentationTimeUs,
                                0
                            )
                            extractor.advance()
                        }
                    }

                    val encoderOutputBufferId = encoder.dequeueOutputBuffer(bufferInfo, 10_000)
                    if (encoderOutputBufferId >= 0) {
                        val encodedData = encoder.getOutputBuffer(encoderOutputBufferId)!!
                        if (bufferInfo.size != 0) {
                            if (!muxerStarted) {
                                val newFormat = encoder.outputFormat
                                trackIndexOut = muxer.addTrack(newFormat)
                                muxer.start()
                                muxerStarted = true
                            }
                            encodedData.position(bufferInfo.offset)
                            encodedData.limit(bufferInfo.offset + bufferInfo.size)
                            muxer.writeSampleData(trackIndexOut, encodedData, bufferInfo)
                        }
                        encoder.releaseOutputBuffer(encoderOutputBufferId, false)
                    }
                }

                extractor.release()
                decoder.stop(); decoder.release()
                encoder.stop(); encoder.release()
                muxer.stop(); muxer.release()
                outputSurface.release()

                onComplete(true)
            } catch (e: Exception) {
                Log.e("VideoProcessor", "Error processing video", e)
                onComplete(false)
            }
        }.start()
    }
}
