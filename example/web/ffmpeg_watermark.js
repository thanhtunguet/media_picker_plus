// This file must be included in web/index.html after ffmpeg.min.js and ffmpeg-core.js
// Expose a global function for Dart interop
window.addWatermarkToVideo = async function (file, watermarkText, position) {
    // Load ffmpeg.js
    if (!window.createFFmpeg) {
        throw new Error('ffmpeg.js is not loaded');
    }
    const { createFFmpeg, fetchFile } = window.FFmpeg;
    const ffmpeg = createFFmpeg({ log: true });
    if (!ffmpeg.isLoaded()) {
        await ffmpeg.load();
    }
    // Write the input file
    ffmpeg.FS('writeFile', 'input.mp4', await fetchFile(file));
    // Build the drawtext filter for watermark
    const drawtext = `drawtext=text='${watermarkText}':fontcolor=white:fontsize=24:x=10:y=H-th-10`;
    // Run ffmpeg command
    await ffmpeg.run(
        '-i', 'input.mp4',
        '-vf', drawtext,
        '-codec:a', 'copy',
        'output.mp4'
    );
    // Read the output file
    const data = ffmpeg.FS('readFile', 'output.mp4');
    // Create a Blob and return an object URL
    const videoBlob = new Blob([data.buffer], { type: 'video/mp4' });
    return URL.createObjectURL(videoBlob);
}; 