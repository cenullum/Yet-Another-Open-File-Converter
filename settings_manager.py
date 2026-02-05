from PySide6.QtCore import QSettings
from logger import app_logger

class SettingsManager:
    """Handles persistent storage of application settings using QSettings."""
    def __init__(self):
        # Initialize QSettings with company and application name
        self.settings = QSettings("Cenker", "YetAnotherOpenFileConverter")
        app_logger.info("SettingsManager initialized.")

    def save_setting(self, key, value):
        """Save a single key-value pair."""
        self.settings.setValue(key, value)
        app_logger.info(f"Setting saved: {key}={value}")

    def get_setting(self, key, default=None):
        """Retrieve a value for a given key, or return default."""
        # Define hardcoded defaults for certain keys if not explicitly provided
        hardcoded_defaults = {
            "target_vid_format": "webm",
            "video_fps": "30",
            "image_metadata": "true",
            "video_metadata": "true"
        }
        
        val = self.settings.value(key)
        if val is None:
            return default if default is not None else hardcoded_defaults.get(key, "")
        return val

    def save_all_settings(self, settings_dict):
        """Batch save multiple settings from a dictionary."""
        for key, value in settings_dict.items():
            self.settings.setValue(key, value)
        app_logger.info("Batch settings saved.")

    def load_all_settings(self):
        """Load all stored settings into a dictionary."""
        settings = {}
        for key in self.settings.allKeys():
            settings[key] = self.settings.value(key)
        return settings
