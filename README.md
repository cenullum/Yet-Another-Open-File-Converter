# Yet Another Open File Converter

A simple tool to convert many image and video files at once. I made this to handle basic file tasks with a simple interface.

<img width="1146" height="851" alt="image" src="https://github.com/user-attachments/assets/77849e36-8e64-4679-aa04-a65fbf4114d1" />



## What it does

### Images
- Changes formats (WebP, JPG, PNG, etc.).
- Can resize images.
- Can turn images into black and white.
- Option to keep or remove metadata.

### Videos
- Changes formats (WebM, MP4, MKV, etc.).
- Supports different codecs (automatically filtered by format).
- Can change bitrate, resolution (up to 4K), and FPS.
- Treats GIFs as videos for better compression.
- Shows how much file space you saved after converting.

### Interface
- Drag and drop files or folders.
- Progress bar and status updates.
- Settings are saved automatically.
- Log files are saved in the app data folder for troubleshooting.

## Technical Details

- **Python & PySide6**: Used for the app interface.
- **FFmpeg**: Used for video and GIF processing.
- **ImageMagick**: Used for image processing.

## How to install

1. Install Python 3, FFmpeg, and ImageMagick on your system.
2. Clone this folder.
3. Run `./setup.sh` to install requirements.
4. Run `python3 main.py` to start.

or download appimage from releases page.

## How to build

Use `build_appimage.sh` to build appimage.

## Support

If you want to support this project:
https://cenullum.com/donation

## License

MIT License
