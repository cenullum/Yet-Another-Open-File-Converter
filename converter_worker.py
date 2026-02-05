import os
import subprocess
import re
import math
from PySide6.QtCore import QThread, Signal
from logger import app_logger

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
                
                if ext in ['.jpg', '.jpeg', '.png', '.webp', '.bmp', '.tiff']:
                    out_path = f"{base_no_ext}_converted.{self.target_img_format}"
                    if output_base_dir:
                        out_path = os.path.join(output_base_dir, f"{os.path.basename(base_no_ext)}.{self.target_img_format}")
                    success = self.process_image(file_path, out_path)
                elif ext in ['.mp4', '.avi', '.mkv', '.mov', '.webm', '.flv', '.wmv', '.gif']:
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
        """Convert image using ImageMagick."""
        quality = self.settings.get('image_quality', '80')
        resize = self.settings.get('image_resize', '0')
        grayscale = self.settings.get('image_grayscale', 'false') == 'true'
        preserve_md = self.settings.get('image_metadata', 'true') == 'true'
        
        cmd = ['convert', input_path]
        if not preserve_md: cmd.append('-strip')
        if grayscale: cmd.extend(['-colorspace', 'Gray'])
        if resize != '0' and resize.isdigit():
            cmd.extend(['-resize', f'{resize}x{resize}>'])
        if self.target_img_format in ['jpg', 'webp']:
            cmd.extend(['-quality', quality])
        cmd.append(output_path)
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        return result.returncode == 0

    def get_video_duration(self, path):
        """Get video duration in seconds using ffprobe."""
        try:
            cmd = ['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'default=noprint_wrappers=1:nokey=1', path]
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
        
        cmd = ['ffmpeg', '-i', input_path, '-progress', 'pipe:1', '-nostats']
        
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
