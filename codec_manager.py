import subprocess
import os
import re
import sys
from logger import app_logger

from config import HARDWARE_ENCODER_MAPPINGS

class CodecManager:
    """
    Manages detection of available FFmpeg encoders (Software & Hardware).
    """
    def __init__(self):
        self.available_codecs = set()
        self.hw_accelerated_codecs = {} # Map base_codec -> best_hw_codec
        self._detect_codecs()

    def get_bin_path(self, bin_name):
        """Resolve path to bundled binaries if running in a PyInstaller bundle."""
        full_bin = bin_name
        if os.name == 'nt' and not bin_name.endswith('.exe'):
            full_bin += '.exe'
        
        if getattr(sys, 'frozen', False):
            bundle_path = os.path.join(sys._MEIPASS, full_bin)
            if os.path.exists(bundle_path):
                return bundle_path
        
        return full_bin

    def _detect_codecs(self):
        """Run ffmpeg -encoders and parse output."""
        ffmpeg_bin = self.get_bin_path('ffmpeg')
        try:
            # Using -hide_banner to reduce output noise
            result = subprocess.run([ffmpeg_bin, '-hide_banner', '-encoders'], capture_output=True, text=True)
            output = result.stdout
            
            # Regex to find codecs: " V..... codec_name "
            # 'V' indicates video encoder
            for line in output.splitlines():
                if " V..... " in line:
                    parts = line.split()
                    if len(parts) >= 2:
                        codec_name = parts[1]
                        self.available_codecs.add(codec_name)
            
            app_logger.info(f"Detected {len(self.available_codecs)} video encoders.")
            self._map_hardware_codecs()
            
        except Exception as e:
            app_logger.error(f"Failed to detect codecs: {e}")

    def _map_hardware_codecs(self):
        """Identify available hardware variants for standard codecs using configuration."""
        for base, variants in HARDWARE_ENCODER_MAPPINGS.items():
            for var in variants:
                if var in self.available_codecs:
                    # Found a hardware variant
                    self.hw_accelerated_codecs[base] = var
                    # Priority is handled by order in config list (first available match wins)
                    break

    def get_compatible_codecs(self, format_config_codecs, use_hw_accel):
        """
        Filter and map codecs based on availability and HW setting.
        Returns a list of display names (which are just codec names).
        """
        final_list = []
        
        for codec in format_config_codecs:
            if codec == "copy" or codec == "No Audio": 
                final_list.append(codec)
                continue
            
            # If HW Accel is ON, replace base codec with HW variant IF available
            if use_hw_accel and codec in self.hw_accelerated_codecs:
                hw_variant = self.hw_accelerated_codecs[codec]
                final_list.append(hw_variant)
            else:
                # Otherwise, check if software codec is actually supported by this ffmpeg build
                # Some builds might miss libx265 or libvpx
                # However, for standard codecs we usually assume they exist or fallback. 
                # But to be strict:
                if codec in self.available_codecs or "lib" in codec or "mpeg" in codec:
                    # We add it. Note: 'libx264' might be listed as 'libx264' or just 'h264' depending on build.
                    # Usually ffmpeg lists 'libx264'.
                    final_list.append(codec)
        
        return final_list
