"""
Centralized configuration for supported file formats and codecs.
All formats are based on FFmpeg and ImageMagick capabilities.
"""

# --- Image Format Configurations ---
# All image formats supported by FFmpeg/ImageMagick for conversion
IMAGE_FORMATS = [
    "webp", "jpg", "jpeg", "png", "bmp", "tiff", "tif",
    "ico", "avif", "tga", "ppm", "pgm", 
    "pbm", "pnm", "gif", "exr", "hdr"
]

# --- Video Format Configurations ---
# Maps container formats to their compatible video and audio codecs
VIDEO_FORMAT_CONFIG = {
    "mp4": {
        "video": ["libx264", "libx265", "mpeg4", "libaom-av1", "copy"],
        "audio": ["aac", "mp3", "ac3", "copy", "No Audio"],
        "default_video": "libx264",
        "default_audio": "aac"
    },
    "mkv": {
        "video": ["libx264", "libx265", "libvpx-vp9", "libaom-av1", "mpeg4", "copy"],
        "audio": ["aac", "mp3", "opus", "flac", "vorbis", "copy", "No Audio"],
        "default_video": "libx264",
        "default_audio": "aac"
    },
    "webm": {
        "video": ["libvpx-vp9", "libvpx", "libaom-av1"],
        "audio": ["libopus", "libvorbis", "No Audio"],
        "default_video": "libvpx-vp9",
        "default_audio": "libopus"
    },
    "avi": {
        "video": ["mpeg4", "libxvid", "libx264", "mjpeg", "copy"],
        "audio": ["mp3", "ac3", "pcm_s16le", "copy", "No Audio"],
        "default_video": "mpeg4",
        "default_audio": "mp3"
    },
    "mov": {
        "video": ["libx264", "libx265", "prores", "mjpeg", "copy"],
        "audio": ["aac", "mp3", "pcm_s16le", "copy", "No Audio"],
        "default_video": "libx264",
        "default_audio": "aac"
    },
    "flv": {
        "video": ["flv1", "libx264", "copy"],
        "audio": ["aac", "mp3", "copy", "No Audio"],
        "default_video": "libx264",
        "default_audio": "aac"
    },
    "wmv": {
        "video": ["wmv2", "wmv1", "libx264", "copy"],
        "audio": ["wmav2", "wmav1", "copy", "No Audio"],
        "default_video": "wmv2",
        "default_audio": "wmav2"
    },
    "gif": {
        "video": ["gif"],
        "audio": ["No Audio"],
        "default_video": "gif",
        "default_audio": "No Audio"
    },
    "ogv": {
        "video": ["libtheora", "copy"],
        "audio": ["libvorbis", "libopus", "copy", "No Audio"],
        "default_video": "libtheora",
        "default_audio": "libvorbis"
    },
    "3gp": {
        "video": ["h263", "mpeg4", "libx264", "copy"],
        "audio": ["aac", "amr_nb", "copy", "No Audio"],
        "default_video": "h263",
        "default_audio": "aac"
    },
    "m4v": {
        "video": ["libx264", "libx265", "mpeg4", "copy"],
        "audio": ["aac", "mp3", "copy", "No Audio"],
        "default_video": "libx264",
        "default_audio": "aac"
    },
    "mpg": {
        "video": ["mpeg2video", "mpeg1video", "copy"],
        "audio": ["mp2", "mp3", "ac3", "copy", "No Audio"],
        "default_video": "mpeg2video",
        "default_audio": "mp2"
    },
    "mpeg": {
        "video": ["mpeg2video", "mpeg1video", "copy"],
        "audio": ["mp2", "mp3", "ac3", "copy", "No Audio"],
        "default_video": "mpeg2video",
        "default_audio": "mp2"
    },
    "ts": {
        "video": ["libx264", "libx265", "mpeg2video", "copy"],
        "audio": ["aac", "mp3", "ac3", "copy", "No Audio"],
        "default_video": "libx264",
        "default_audio": "aac"
    },
    "m2ts": {
        "video": ["libx264", "libx265", "mpeg2video", "copy"],
        "audio": ["aac", "ac3", "copy", "No Audio"],
        "default_video": "libx264",
        "default_audio": "aac"
    }
}

VIDEO_FORMATS = list(VIDEO_FORMAT_CONFIG.keys())

# --- Derived Extension Sets ---
# Generate extension sets from the format lists above
SUPPORTED_IMAGE_EXTENSIONS = {f".{fmt}" for fmt in IMAGE_FORMATS}
SUPPORTED_VIDEO_EXTENSIONS = {f".{fmt}" for fmt in VIDEO_FORMATS}
ALL_SUPPORTED_EXTENSIONS = SUPPORTED_IMAGE_EXTENSIONS | SUPPORTED_VIDEO_EXTENSIONS
