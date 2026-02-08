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

# --- Audio Format Configurations ---
AUDIO_FORMATS = ["mp3", "ogg", "flac", "wav", "m4a", "opus"]

# Maps audio formats to their available settings
# has_quality, has_bitrate_mode, has_compression, has_sample_width
AUDIO_FORMAT_CONFIG = {
    "mp3": {
        "encoder": "libmp3lame",
        "has_quality": True,
        "has_bitrate_mode": True,
        "has_compression": False,
        "has_sample_width": False
    },
    "ogg": {
        "encoder": "libvorbis",
        "has_quality": True,
        "has_bitrate_mode": False,
        "has_compression": False,
        "has_sample_width": False
    },
    "flac": {
        "encoder": "flac",
        "has_quality": False,
        "has_bitrate_mode": False,
        "has_compression": True,
        "has_sample_width": False
    },
    "wav": {
        "encoder": "pcm_s16le",
        "has_quality": False,
        "has_bitrate_mode": False,
        "has_compression": False,
        "has_sample_width": True
    },
    "m4a": {
        "encoder": "aac",
        "has_quality": True,
        "has_bitrate_mode": False,
        "has_compression": False,
        "has_sample_width": False
    },
    "opus": {
        "encoder": "libopus",
        "has_quality": True,
        "has_bitrate_mode": False,
        "has_compression": False,
        "has_sample_width": False
    }
}

# Quality levels for audio encoding (maps to encoder-specific values)
AUDIO_QUALITY_LEVELS = [
    "Very Low", "Low", "Normal", "High", "Very High", "Insanely High"
]

# Bitrate modes for MP3
AUDIO_BITRATE_MODES = ["CBR", "ABR", "VBR"]

# Compression levels for FLAC
AUDIO_COMPRESSION_LEVELS = ["Less", "Default", "Better"]

# Sample width options for WAV
AUDIO_SAMPLE_WIDTHS = ["8 bits", "16 bits", "32 bits"]

# Resample rate options in kHz
AUDIO_RESAMPLE_RATES = ["Original", "8", "11", "16", "22", "32", "44", "48", "96", "128"]

# Supported audio input extensions
SUPPORTED_AUDIO_INPUT_EXTENSIONS = {
    ".mp3", ".ogg", ".flac", ".wav", ".m4a", ".opus", 
    ".wma", ".aac", ".aiff", ".aif", ".ape", ".wv"
}

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

SUPPORTED_IMAGE_EXTENSIONS = {f".{fmt}" for fmt in IMAGE_FORMATS}
SUPPORTED_VIDEO_EXTENSIONS = {f".{fmt}" for fmt in VIDEO_FORMATS}
ALL_SUPPORTED_EXTENSIONS = SUPPORTED_IMAGE_EXTENSIONS | SUPPORTED_VIDEO_EXTENSIONS | SUPPORTED_AUDIO_INPUT_EXTENSIONS

# --- Hardware Encoder Mappings ---
# Maps base software codecs to their potential hardware-accelerated variants.
# Priority is often determined by the order in which they are checked or system availability.
HARDWARE_ENCODER_MAPPINGS = {
    "libx264": ["h264_nvenc", "h264_amf", "h264_qsv", "h264_videotoolbox", "h264_vaapi"],
    "libx265": ["hevc_nvenc", "hevc_amf", "hevc_qsv", "hevc_videotoolbox", "hevc_vaapi"],
    "libvpx-vp9": ["vp9_qsv", "vp9_vaapi", "vp9_amf"], 
    "libaom-av1": ["av1_nvenc", "av1_qsv", "av1_amf", "av1_vaapi"],
    "mpeg2video": ["mpeg2_qsv", "mpeg2_vaapi"],
    "mjpeg": ["mjpeg_qsv", "mjpeg_vaapi"]
}
