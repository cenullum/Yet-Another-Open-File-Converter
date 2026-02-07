import os
import subprocess
import re
import math
import sys
from PySide6.QtCore import QThread, Signal
from logger import app_logger
from config import SUPPORTED_IMAGE_EXTENSIONS, SUPPORTED_VIDEO_EXTENSIONS

class ConverterWorker(QThread):
    """
    Background worker thread for processing file conversions.
    Handles both images (via ImageMagick) and videos/GIFs (via FFmpeg).
    Supports real-time progress parsing for video and folder-aware output.
    """
    progress = Signal(int) # 0-1000 for granularity
    status = Signal(str)
    finished = Signal(bool, str)

    def __init__(self, files, target_img_format, target_vid_format, settings, source_folder_name=""):
        super().__init__()
        self.files = files
        self.target_img_format = target_img_format
        self.target_vid_format = target_vid_format
        self.settings = settings
        self.source_folder_name = source_folder_name
        self.is_cancelled = False
        app_logger.info(f"ConverterWorker initialized. Files: {len(files)}, Folder: {source_folder_name}")

    def get_bin_path(self, bin_name):
        """Resolve path to bundled binaries if running in a PyInstaller bundle."""
        full_bin = bin_name
        if os.name == 'nt' and not bin_name.endswith('.exe'):
            full_bin += '.exe'
        
        if getattr(sys, 'frozen', False):
            bundle_path = os.path.join(sys._MEIPASS, full_bin)
            if os.path.exists(bundle_path):
                return bundle_path
        
        return full_bin # Fallback to system PATH

    def run(self):
        """
        Main execution loop. Manages output directories and aggregates results.
        """
        total_files = len(self.files)
        if total_files == 0:
            self.finished.emit(True, "No files to convert.")
            return

        success_count = 0
        failed_files = []
        total_orig_bytes = 0
        total_conv_bytes = 0

        # Handle folder-based output
        output_base_dir = ""
        if self.source_folder_name:
            # Create a 'folder_name_converted' directory in the parent of the first file
            parent_dir = os.path.dirname(self.files[0])
            output_base_dir = os.path.join(parent_dir, f"{self.source_folder_name}_converted")
            os.makedirs(output_base_dir, exist_ok=True)
            app_logger.info(f"Folder-aware mode: saving to {output_base_dir}")

        for i, file_path in enumerate(self.files):
            if self.is_cancelled:
                app_logger.warning("Conversion cancelled.")
                break

            file_name = os.path.basename(file_path)
            try:
                self.status.emit(f"Processing: {file_name}")
                app_logger.info(f"Starting: {file_path}")
                
                orig_size = os.path.getsize(file_path)
                total_orig_bytes += orig_size
                
                # Determine output path
                if output_base_dir:
                    base_no_ext = os.path.splitext(file_name)[0]
                else:
                    base_no_ext = os.path.splitext(file_path)[0]

                ext = os.path.splitext(file_path)[1].lower()
                
                if ext in SUPPORTED_IMAGE_EXTENSIONS:
                    out_path = f"{base_no_ext}_converted.{self.target_img_format}"
                    if output_base_dir:
                        out_path = os.path.join(output_base_dir, f"{os.path.basename(base_no_ext)}.{self.target_img_format}")
                    success = self.process_image(file_path, out_path)
                elif ext in SUPPORTED_VIDEO_EXTENSIONS:
                    out_path = f"{base_no_ext}_converted.{self.target_vid_format}"
                    if output_base_dir:
                        out_path = os.path.join(output_base_dir, f"{os.path.basename(base_no_ext)}.{self.target_vid_format}")
                    success = self.process_video(file_path, out_path, i, total_files)
                else:
                    app_logger.warning(f"Skipping unsupported format: {ext}")
                    success = False
                    out_path = None

                if success and out_path and os.path.exists(out_path):
                    success_count += 1
                    total_conv_bytes += os.path.getsize(out_path)
                    app_logger.info(f"Finished: {file_name}")
                else:
                    failed_files.append(file_name)
                    app_logger.error(f"Failed: {file_name}")
                
                # Update global progress (per file completion)
                # If it's a video, process_video already updated sub-progress
                self.progress.emit(int(((i + 1) / total_files) * 1000))

            except Exception as e:
                failed_files.append(file_name)
                app_logger.error(f"Error in worker: {str(e)}")

        # Final Summary
        is_success = len(failed_files) == 0
        summary = self.format_summary(success_count, failed_files, total_orig_bytes, total_conv_bytes)
        self.finished.emit(is_success, summary)

    def process_image(self, input_path, output_path):
        """Convert image using FFmpeg."""
        quality = self.settings.get('image_quality', '80')
        resize = self.settings.get('image_resize', '0')
        grayscale = self.settings.get('image_grayscale', 'false') == 'true'
        preserve_md = self.settings.get('image_metadata', 'true') == 'true'
        
        ffmpeg_bin = self.get_bin_path('ffmpeg')
        cmd = [ffmpeg_bin, '-y', '-i', input_path]
        
        if not preserve_md:
            cmd.extend(['-map_metadata', '-1'])
        
        # Build filter graph
        vf = []
        if grayscale:
            vf.append('format=gray')
        
        if resize != '0' and resize.isdigit():
            # Scale longest side to 'resize' while maintaining aspect ratio, and only if original is larger
            vf.append(f"scale='if(gt(iw,ih),min({resize},iw),-1)':'if(gt(ih,iw),min({resize},ih),-1)'")
        
        if vf:
            cmd.extend(['-vf', ','.join(vf)])
            
        # Format-specific encoder and quality settings
        fmt = self.target_img_format.lower()
        
        if fmt == 'webp':
            cmd.extend(['-c:v', 'libwebp', '-q:v', quality])
        
        elif fmt in ['jpg', 'jpeg']:
            cmd.extend(['-c:v', 'mjpeg'])
            # FFmpeg uses 1-31 scale for JPEG, where 1 is best. Map 1-100 to 31-1.
            try:
                q_val = int(quality)
                mapped_q = max(1, min(31, int(31 - (q_val * 30 / 100))))
                cmd.extend(['-q:v', str(mapped_q)])
            except:
                cmd.extend(['-q:v', '5'])
        
        elif fmt == 'png':
            cmd.extend(['-c:v', 'png'])
        
        elif fmt == 'bmp':
            cmd.extend(['-c:v', 'bmp'])
        
        elif fmt in ['tiff', 'tif']:
            cmd.extend(['-c:v', 'tiff'])
        
        elif fmt == 'avif':
            try:
                crf = max(0, min(63, 63 - int(quality) * 63 // 100))
                cmd.extend(['-c:v', 'libaom-av1', '-crf', str(crf)])
            except:
                cmd.extend(['-c:v', 'libaom-av1', '-crf', '30'])
        

        elif fmt == 'ico':
            # ICO format - scale to 256x256 max and use ICO format
            if resize == '0' or not resize.isdigit() or int(resize) > 256:
                if vf:
                    cmd[-1] = cmd[-1] + ",scale='min(256,iw)':'min(256,ih)'"
                else:
                    cmd.extend(['-vf', "scale='min(256,iw)':'min(256,ih)'"])
            cmd.extend(['-c:v', 'bmp', '-f', 'ico'])
        
        elif fmt == 'tga':
            cmd.extend(['-c:v', 'targa'])
        
        elif fmt in ['ppm', 'pgm', 'pbm', 'pnm']:
            # Portable anymap formats - use image2 format
            cmd.extend(['-f', 'image2', '-c:v', 'ppm'])
        
        elif fmt == 'gif':
            cmd.extend(['-c:v', 'gif'])
        
        elif fmt in ['exr', 'hdr']:
            # High dynamic range formats
            if fmt == 'exr':
                cmd.extend(['-c:v', 'exr'])
            else:
                # HDR uses Radiance format
                cmd.extend(['-pix_fmt', 'rgb48le'])

            
        cmd.append(output_path)
        
        app_logger.info(f"Image conversion command: {' '.join(cmd)}")
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            app_logger.error(f"FFmpeg error: {result.stderr}")
        
        return result.returncode == 0

    def get_video_duration(self, path):
        """Get video duration in seconds using ffprobe."""
        try:
            ffprobe_bin = self.get_bin_path('ffprobe')
            cmd = [ffprobe_bin, '-v', 'error', '-show_entries', 'format=duration', '-of', 'default=noprint_wrappers=1:nokey=1', path]
            result = subprocess.run(cmd, capture_output=True, text=True)
            return float(result.stdout.strip())
        except:
            return 0

    def process_video(self, input_path, output_path, file_index, total_files):
        """Convert video using FFmpeg with real-time progress parsing."""
        v_codec = self.settings.get('video_codec', 'libx264')
        a_codec = self.settings.get('audio_codec', 'aac')
        bitrate = self.settings.get('video_bitrate', '2500k')
        res = self.settings.get('video_resolution', 'Original')
        fps = self.settings.get('video_fps', '30')
        preserve_md = self.settings.get('video_metadata', 'true') == 'true'
        
        duration = self.get_video_duration(input_path)
        
        ffmpeg_bin = self.get_bin_path('ffmpeg')
        cmd = [ffmpeg_bin, '-i', input_path, '-progress', 'pipe:1', '-nostats']
        
        if preserve_md: cmd.extend(['-map_metadata', '0'])
        else: cmd.extend(['-map_metadata', '-1'])
            
        # Audio handling
        if a_codec == "No Audio":
            cmd.append('-an')
        else:
            cmd.extend(['-c:a', a_codec])

        # Filters
        vf = []
        if res != 'Original':
            h = res.split('(')[-1].replace('p)', '') if '(' in res else res.replace('p', '')
            if h.isdigit(): vf.append(f"scale=-2:{h}")
        if vf: cmd.extend(['-vf', ','.join(vf)])
            
        if fps != '0' and fps.isdigit(): cmd.extend(['-r', fps])
            
        cmd.extend(['-c:v', v_codec, '-b:v', bitrate, '-y', output_path])
        
        app_logger.info(f"FFmpeg command: {' '.join(cmd)}")
        
        # Start FFmpeg and parse output
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)
        
        while True:
            line = process.stdout.readline()
            if not line:
                break
            
            # Parse progress: out_time_ms=...
            if 'out_time_ms=' in line and duration > 0:
                try:
                    ms = int(line.split('=')[1].strip())
                    secs = ms / 1000000.0
                    progress_pct = (secs / duration) * 100
                    # Scale based on current file index
                    base_progress = (file_index / total_files) * 1000
                    file_slice = (1.0 / total_files) * 1000
                    current_total_progress = base_progress + (progress_pct / 100.0) * file_slice
                    self.progress.emit(int(current_total_progress))
                except:
                    pass

        process.wait()
        return process.returncode == 0

    def format_summary(self, success_count, failed_files, orig_bytes, conv_bytes):
        """Build a human-readable summary of the conversion results."""
        def to_human(size_bytes):
            if size_bytes == 0: return "0B"
            units = ("B", "KB", "MB", "GB")
            i = int(math.floor(math.log(size_bytes, 1024)))
            p = math.pow(1024, i)
            s = round(size_bytes / p, 2)
            return f"{s} {units[i]}"

        reduction = 0
        if orig_bytes > 0:
            reduction = ((orig_bytes - conv_bytes) / orig_bytes) * 100

        msg = f"Finished! Successfully converted {success_count} files.\n"
        if failed_files:
            msg += f"Errors in {len(failed_files)} files: {', '.join(failed_files[:3])}...\n"
        
        msg += f"\nTotal Original: {to_human(orig_bytes)}"
        msg += f"\nTotal Processed: {to_human(conv_bytes)}"
        msg += f"\nSpace Saved: {reduction:.1f}%"
        return msg

    def cancel(self):
        self.is_cancelled = True
