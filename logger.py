import logging
from PySide6.QtCore import QStandardPaths
import os
from datetime import datetime

class Logger:
    """Utility class to manage application logging in the standard config directory."""
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(Logger, cls).__new__(cls)
            cls._instance._setup_logger()
        return cls._instance

    def _setup_logger(self):
        """Configure the logging system in the application's data directory."""
        # Use QStandardPaths to find a suitable location (same as settings)
        base_dir = QStandardPaths.writableLocation(QStandardPaths.AppDataLocation)
        self.log_dir = os.path.join(base_dir, "logs")
        
        if not os.path.exists(self.log_dir):
            os.makedirs(self.log_dir, exist_ok=True)

        log_file = os.path.join(self.log_dir, "yet_another_open_file_converter_log.txt")
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_file, encoding='utf-8'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)

    def info(self, message):
        self.logger.info(message)

    def error(self, message):
        self.logger.error(message)

    def warning(self, message):
        self.logger.warning(message)

    def get_log_dir(self):
        """Return the directory where logs are stored."""
        return self.log_dir

# Global logger instance
app_logger = Logger()
