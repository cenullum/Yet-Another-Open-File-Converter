MAIN_STYLE = """
QMainWindow {
    background-color: #1a1a1a;
}

QWidget {
    font-family: 'Segoe UI', 'Roboto', 'Arial';
    color: #e0e0e0;
}

#DropArea {
    border: 2px dashed #4a90e2;
    border-radius: 15px;
    background-color: #262626;
    margin: 20px;
}

#DropArea[dragged=true] {
    background-color: #333333;
    border: 2px dashed #ffffff;
}

QLabel#DropLabel {
    font-size: 24px;
    font-weight: bold;
    color: #4a90e2;
}

QPushButton {
    background-color: #4a90e2;
    color: white;
    border-radius: 8px;
    padding: 10px 20px;
    font-size: 14px;
    font-weight: bold;
    border: none;
}

QPushButton:hover {
    background-color: #357abd;
}

QPushButton:pressed {
    background-color: #2a5a8e;
}

QPushButton#SettingsButton {
    background-color: #444444;
}

QPushButton#SettingsButton:hover {
    background-color: #555555;
}

QProgressBar {
    border: 1px solid #444444;
    border-radius: 5px;
    text-align: center;
    height: 20px;
}

QProgressBar::chunk {
    background-color: #4a90e2;
    border-radius: 5px;
}

QListWidget {
    background-color: #262626;
    border: 1px solid #444444;
    border-radius: 10px;
    padding: 5px;
}

QDialog {
    background-color: #1a1a1a;
}

QTabWidget::pane {
    border: 1px solid #444444;
    top: -1px;
    background-color: #1a1a1a;
}

QTabBar::tab {
    background-color: #262626;
    border: 1px solid #444444;
    padding: 8px 15px;
    border-top-left-radius: 4px;
    border-top-right-radius: 4px;
    min-width: 100px;
}

QTabBar::tab:selected {
    background-color: #4a90e2;
    color: white;
}

QLineEdit, QComboBox {
    background-color: #333333;
    border: 1px solid #444444;
    border-radius: 4px;
    padding: 5px;
    color: white;
}

QCheckBox {
    spacing: 5px;
}

QCheckBox::indicator {
    width: 18px;
    height: 18px;
}

#GithubLink {
    color: #4a90e2;
    text-decoration: none;
    font-size: 12px;
}

#GithubLink:hover {
    color: #357abd;
}
"""
