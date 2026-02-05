import sys
import os
import subprocess
from PySide6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                             QHBoxLayout, QLabel, QPushButton, QListWidget, 
                             QProgressBar, QFileDialog, QDialog, QFormLayout, 
                             QLineEdit, QComboBox, QMessageBox, QTabWidget, 
                             QCheckBox, QFrame)
from PySide6.QtCore import Qt, QMimeData, Signal, QUrl
from PySide6.QtGui import QDragEnterEvent, QDropEvent, QDesktopServices

from styles import MAIN_STYLE
from settings_manager import SettingsManager
from converter_worker import ConverterWorker
from logger import app_logger

# Mapping of container formats to supported video and audio codecs
FORMAT_CONFIG = {
    "webm": {
        "video": ["libvpx-vp9", "libvpx"],
        "audio": ["libopus", "libvorbis", "No Audio"]
    },
    "mp4": {
        "video": ["libx264", "libx265", "copy"],
        "audio": ["aac", "mp3", "copy", "No Audio"]
    },
    "mkv": {
        "video": ["libx264", "libx265", "libvpx-vp9", "copy"],
        "audio": ["aac", "mp3", "libopus", "copy", "No Audio"]
    },
    "avi": {
        "video": ["libxvid", "mpeg4", "copy"],
        "audio": ["mp3", "ac3", "copy", "No Audio"]
    },
    "mov": {
        "video": ["libx264", "libx265", "copy"],
        "audio": ["aac", "mp3", "copy", "No Audio"]
    }
}

class SettingsDialog(QDialog):
    """Dialogue for adjusting image, video, and general settings."""
    def __init__(self, settings_manager, parent=None):
        super().__init__(parent)
        self.settings_manager = settings_manager
        self.setWindowTitle("Settings")
        self.setMinimumWidth(450)
        
        main_layout = QVBoxLayout(self)
        self.tabs = QTabWidget()
        
        # --- Image Tab ---
        self.image_tab = QWidget()
        img_layout = QFormLayout(self.image_tab)
        
        self.target_img_format = QComboBox()
        self.target_img_format.addItems(["webp", "jpg", "png", "bmp", "tiff"])
        self.target_img_format.setCurrentText(self.settings_manager.get_setting("target_img_format", "webp"))
        self.target_img_format.currentTextChanged.connect(self.update_ui_state)
        img_layout.addRow("Format:", self.target_img_format)
        
        self.img_quality = QLineEdit()
        self.img_quality.setText(self.settings_manager.get_setting("image_quality", "80"))
        img_layout.addRow("Quality (1-100):", self.img_quality)
        
        self.img_resize = QLineEdit()
        self.img_resize.setPlaceholderText("e.g. 1920")
        self.img_resize.setText(self.settings_manager.get_setting("image_resize", "0"))
        img_layout.addRow("Resize (Longest Side):", self.img_resize)
        
        self.img_grayscale = QCheckBox("Black & White")
        self.img_grayscale.setChecked(self.settings_manager.get_setting("image_grayscale", "false") == "true")
        img_layout.addRow("", self.img_grayscale)

        self.img_metadata = QCheckBox("Keep Metadata")
        self.img_metadata.setChecked(self.settings_manager.get_setting("image_metadata", "true") == "true")
        img_layout.addRow("", self.img_metadata)
        
        hint_img = QLabel("Tip: 0 means original size.")
        hint_img.setStyleSheet("color: gray; font-size: 10px;")
        img_layout.addRow("", hint_img)
        
        self.tabs.addTab(self.image_tab, "Image")
        
        # --- Video Tab ---
        self.video_tab = QWidget()
        vid_layout = QFormLayout(self.video_tab)
        
        self.target_vid_format = QComboBox()
        self.target_vid_format.addItems(list(FORMAT_CONFIG.keys()))
        self.target_vid_format.setCurrentText(self.settings_manager.get_setting("target_vid_format", "webm"))
        self.target_vid_format.currentTextChanged.connect(self.update_ui_state)
        vid_layout.addRow("Format:", self.target_vid_format)
        
        self.video_codec = QComboBox()
        vid_layout.addRow("Video Codec:", self.video_codec)
        
        self.audio_codec = QComboBox()
        vid_layout.addRow("Audio Codec:", self.audio_codec)
        
        self.video_bitrate = QLineEdit()
        self.video_bitrate.setText(self.settings_manager.get_setting("video_bitrate", "2500k"))
        vid_layout.addRow("Bitrate (e.g. 2500k):", self.video_bitrate)
        
        self.video_res = QComboBox()
        self.video_res.addItems(["Original", "4K (2160p)", "2K (1440p)", "1080p", "720p", "480p", "360p"])
        self.video_res.setCurrentText(self.settings_manager.get_setting("video_resolution", "Original"))
        vid_layout.addRow("Scale:", self.video_res)
        
        self.video_fps = QLineEdit()
        self.video_fps.setText(self.settings_manager.get_setting("video_fps", "30"))
        vid_layout.addRow("FPS:", self.video_fps)

        self.video_metadata = QCheckBox("Keep Metadata")
        self.video_metadata.setChecked(self.settings_manager.get_setting("video_metadata", "true") == "true")
        vid_layout.addRow("", self.video_metadata)

        hint_vid = QLabel("Tip: 0 FPS means original rate.")
        hint_vid.setStyleSheet("color: gray; font-size: 10px;")
        vid_layout.addRow("", hint_vid)
        
        self.tabs.addTab(self.video_tab, "Video")

        # --- Help Tab ---
        self.help_tab = QWidget()
        help_vbox = QVBoxLayout(self.help_tab)
        
        help_info = QLabel("Yet Another Open File Converter\nSimple batch conversion tool.")
        help_info.setAlignment(Qt.AlignCenter)
        help_vbox.addWidget(help_info)
        
        self.btn_github = QPushButton("GitHub Repository")
        self.btn_github.clicked.connect(self.open_link)
        help_vbox.addWidget(self.btn_github)

        self.btn_donate = QPushButton("Support the Project ☕")
        self.btn_donate.setObjectName("DonationButton")
        self.btn_donate.clicked.connect(self.open_donation)
        help_vbox.addWidget(self.btn_donate)
        
        self.btn_log_folder = QPushButton("View Log Folder")
        self.btn_log_folder.setObjectName("SettingsButton")
        self.btn_log_folder.clicked.connect(self.open_logs)
        help_vbox.addWidget(self.btn_log_folder)
        
        help_vbox.addStretch()
        self.tabs.addTab(self.help_tab, "Help")
        
        main_layout.addWidget(self.tabs)
        
        save_btn = QPushButton("Save")
        save_btn.clicked.connect(self.save_settings)
        main_layout.addWidget(save_btn)
        
        self.update_ui_state()

    def update_ui_state(self):
        """Update fields based on current format selections."""
        # Image quality visibility
        img_fmt = self.target_img_format.currentText()
        self.img_quality.setEnabled(img_fmt in ["webp", "jpg"])
        
        # Video/Audio codec filtering
        vid_fmt = self.target_vid_format.currentText()
        if vid_fmt in FORMAT_CONFIG:
            # Update Video Codecs
            self.video_codec.clear()
            self.video_codec.addItems(FORMAT_CONFIG[vid_fmt]["video"])
            saved_v = self.settings_manager.get_setting("video_codec", "")
            if saved_v in FORMAT_CONFIG[vid_fmt]["video"]:
                self.video_codec.setCurrentText(saved_v)
            
            # Update Audio Codecs
            self.audio_codec.clear()
            self.audio_codec.addItems(FORMAT_CONFIG[vid_fmt]["audio"])
            saved_a = self.settings_manager.get_setting("audio_codec", "")
            if saved_a in FORMAT_CONFIG[vid_fmt]["audio"]:
                self.audio_codec.setCurrentText(saved_a)

    def open_link(self):
        QDesktopServices.openUrl(QUrl("https://github.com/cenullum/Yet-Another-Open-File-Converter"))

    def open_donation(self):
        QDesktopServices.openUrl(QUrl("https://cenullum.com/donation"))

    def open_logs(self):
        log_dir = app_logger.get_log_dir()
        if os.path.exists(log_dir):
            QDesktopServices.openUrl(QUrl.fromLocalFile(log_dir))

    def save_settings(self):
        """Persist all settings."""
        settings = {
            "target_img_format": self.target_img_format.currentText(),
            "image_quality": self.img_quality.text(),
            "image_resize": self.img_resize.text(),
            "image_grayscale": "true" if self.img_grayscale.isChecked() else "false",
            "image_metadata": "true" if self.img_metadata.isChecked() else "false",
            "target_vid_format": self.target_vid_format.currentText(),
            "video_codec": self.video_codec.currentText(),
            "audio_codec": self.audio_codec.currentText(),
            "video_bitrate": self.video_bitrate.text(),
            "video_resolution": self.video_res.currentText(),
            "video_fps": self.video_fps.text(),
            "video_metadata": "true" if self.video_metadata.isChecked() else "false"
        }
        self.settings_manager.save_all_settings(settings)
        self.accept()

class DropArea(QLabel):
    """Area for file drop interactions. Emits list of files and optional folder name."""
    files_dropped = Signal(list, str) # files, folder_name

    def __init__(self):
        super().__init__("Drag and Drop Files Here")
        self.setObjectName("DropArea")
        self.setAlignment(Qt.AlignCenter)
        self.setAcceptDrops(True)
        self.setMinimumHeight(200)

    def dragEnterEvent(self, event: QDragEnterEvent):
        if event.mimeData().hasUrls():
            event.acceptProposedAction()
            self.setProperty("dragged", True)
            self.update_style()

    def dragLeaveEvent(self, event):
        self.setProperty("dragged", False)
        self.update_style()

    def dropEvent(self, event: QDropEvent):
        urls = event.mimeData().urls()
        collected = []
        folder_name = ""
        
        # If dropping exacty one folder, we track its name for output separation
        if len(urls) == 1:
            path = urls[0].toLocalFile()
            if os.path.isdir(path):
                folder_name = os.path.basename(path)

        for url in urls:
            path = url.toLocalFile()
            if os.path.isdir(path):
                for root, _, names in os.walk(path):
                    for n in names:
                        collected.append(os.path.join(root, n))
            else:
                collected.append(path)
                
        self.files_dropped.emit(collected, folder_name)
        self.setProperty("dragged", False)
        self.update_style()

    def update_style(self):
        self.style().unpolish(self)
        self.style().polish(self)

class MainWindow(QMainWindow):
    """Primary application interface."""
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Yet Another Open File Converter")
        self.resize(600, 750)
        self.setStyleSheet(MAIN_STYLE)
        
        self.settings_manager = SettingsManager()
        self.files_to_convert = []
        self.source_folder_name = ""

        central = QWidget()
        self.setCentralWidget(central)
        layout = QVBoxLayout(central)
        
        title = QLabel("Yet Another Open File Converter")
        title.setStyleSheet("font-size: 26px; font-weight: bold; margin-bottom: 5px;")
        title.setAlignment(Qt.AlignCenter)
        layout.addWidget(title)

        self.drop_area = DropArea()
        self.drop_area.files_dropped.connect(self.handle_files)
        layout.addWidget(self.drop_area)

        self.file_list = QListWidget()
        layout.addWidget(self.file_list)

        btns = QHBoxLayout()
        self.btn_convert = QPushButton("Convert Now")
        self.btn_convert.clicked.connect(self.start_process)
        
        self.btn_settings = QPushButton("Settings")
        self.btn_settings.setObjectName("SettingsButton")
        self.btn_settings.clicked.connect(self.show_settings)
        
        btns.addWidget(self.btn_convert)
        btns.addWidget(self.btn_settings)
        layout.addLayout(btns)

        self.progress = QProgressBar()
        self.progress.setVisible(False)
        # Higher granularity for smoother movement
        self.progress.setRange(0, 1000) 
        layout.addWidget(self.progress)
        
        self.status = QLabel("Ready")
        layout.addWidget(self.status)

    def handle_files(self, files, folder_name=""):
        """Filter files by extension and store folder context if applicable."""
        exts = ['.jpg', '.jpeg', '.png', '.webp', '.bmp', '.tiff', '.mp4', 
                '.avi', '.mkv', '.mov', '.webm', '.flv', '.wmv', '.gif']
        self.files_to_convert = [f for f in files if os.path.splitext(f)[1].lower() in exts]
        self.source_folder_name = folder_name
        
        self.file_list.clear()
        for f in self.files_to_convert:
            self.file_list.addItem(os.path.basename(f))
        
        if not self.files_to_convert:
            QMessageBox.warning(self, "Input Error", "No supported files found.")
        else:
            context = f"from folder '{folder_name}'" if folder_name else ""
            self.status.setText(f"Staged {len(self.files_to_convert)} files {context}.")

    def show_settings(self):
        SettingsDialog(self.settings_manager, self).exec()

    def start_process(self):
        if not self.files_to_convert:
            QMessageBox.warning(self, "Empty", "Drop files before converting.")
            return

        self.progress.setValue(0)
        self.progress.setVisible(True)
        self.btn_convert.setEnabled(False)
        
        settings = self.settings_manager.load_all_settings()
        img_fmt = self.settings_manager.get_setting("target_img_format", "webp")
        vid_fmt = self.settings_manager.get_setting("target_vid_format", "webm")
        
        self.worker = ConverterWorker(self.files_to_convert, img_fmt, vid_fmt, settings, self.source_folder_name)
        self.worker.progress.connect(self.update_progress)
        self.worker.status.connect(self.status.setText)
        self.worker.finished.connect(self.finish_ui)
        self.worker.start()

    def update_progress(self, val):
        """Update progress bar with high-granularity value (0-1000)."""
        self.progress.setValue(val)

    def finish_ui(self, success, msg):
        self.btn_convert.setEnabled(True)
        self.progress.setVisible(False)
        
        # Custom message box with Open Logs button
        box = QMessageBox(self)
        box.setWindowTitle("Conversion Finished")
        box.setText(msg)
        box.setIcon(QMessageBox.Information if success else QMessageBox.Warning)
        
        btn_ok = box.addButton(QMessageBox.Ok)
        btn_logs = box.addButton("Open Logs", QMessageBox.ActionRole)
        
        box.exec()
        
        if box.clickedButton() == btn_logs:
            log_dir = app_logger.get_log_dir()
            if os.path.exists(log_dir):
                QDesktopServices.openUrl(QUrl.fromLocalFile(log_dir))
        
        self.files_to_convert = []
        self.file_list.clear()
        self.status.setText("Ready")

if __name__ == "__main__":
    app_logger.info("Initializing application.")
    app = QApplication(sys.argv)
    win = MainWindow()
    win.show()
    sys.exit(app.exec())
