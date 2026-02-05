# CMO Meter OCR App

<p align="center">
  <img src="assets/icons/app_icon.png" alt="CMO App Logo" width="120" height="120">
</p>

<p align="center">
  <strong>Smart Meter Reading & CMO Management Solution</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#download">Download</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#installation">Installation</a> •
  <a href="#user-guide">User Guide</a>
</p>

---

## About This App

**CMO Meter OCR App** is a powerful mobile application developed by **OTBL (Oculin Tech BD Ltd)** for utility meter reading and Change Meter Owner (CMO) management. The app uses advanced **OCR (Optical Character Recognition)** technology powered by Google ML Kit to automatically read meter displays, eliminating manual data entry errors and increasing field worker productivity.

### Why CMO Meter OCR App?

| Problem | Solution |
|---------|----------|
| Manual meter reading errors | AI-powered OCR automatically reads meter displays |
| Paper-based data collection | Digital forms with offline storage |
| Lost or damaged records | Secure local database with cloud sync |
| Slow data processing | Instant barcode/QR scanning for meter IDs |
| No connectivity in field | Full offline functionality |

---

## Features

### Core Features

| Feature | Description |
|---------|-------------|
| **OCR Meter Reading** | Automatically extract meter readings from photos using ML Kit |
| **Barcode/QR Scanning** | Instantly scan meter IDs and customer codes |
| **Camera Capture** | Take photos of meters, seals, and installation sites |
| **Offline Mode** | Works without internet - sync when connected |
| **Multi-step Forms** | Easy-to-use guided workflow for CMO requests |

### CMO Management

- **Customer Information**: Name, mobile, email, NID, NOCS
- **Meter Details**: Customer ID, new meter ID, old meter info
- **Seal Information**: Battery cover seal, terminal seals (A, B, C)
- **Installation Details**: Date, installer name, steel box status
- **Status Tracking**: Draft → Pending → Uploaded

### Technical Features

- **Secure Authentication**: Encrypted password storage
- **Local Database**: SQLite for reliable offline storage
- **Image Compression**: Optimized photo storage
- **GPS Location**: Geotag meter installations
- **Data Export**: Export records for reporting

---

## Download

### Current Version

| Info | Details |
|------|---------|
| **Version** | 1.0.0 |
| **Build Number** | 1 |
| **Release Date** | February 2026 |
| **Size** | ~97 MB |
| **Android** | 5.0+ (API 21) |

### System Requirements

- **Operating System**: Android 5.0 (Lollipop) or higher
- **RAM**: Minimum 2GB recommended
- **Storage**: At least 200MB free space
- **Camera**: Required for OCR and barcode scanning
- **Permissions**: Camera, Storage, Location (optional)

---

## Screenshots

| Home Dashboard | OCR Scanning | CMO Form |
|----------------|--------------|----------|
| View statistics and recent activities | Point camera at meter to read | Easy multi-step form |

---

## Installation

### For End Users

1. Download the APK file from the releases section
2. Enable "Install from Unknown Sources" in Settings
3. Open the APK file and tap Install
4. Launch the app and register a new account

### For Developers

```bash
# Clone the repository
git clone https://github.com/otbl/cmo-meter-ocr.git

# Navigate to project
cd cmo-meter-ocr

# Install dependencies
flutter pub get

# Run the app
flutter run

# Build release APK
flutter build apk --release
```

---

## User Guide

### Quick Start

1. **Register**: Create a new account with your details
2. **Login**: Use your credentials to access the app
3. **Create CMO**: Tap the + button to start a new CMO request
4. **Scan**: Use barcode scanner for customer/meter IDs
5. **Capture**: Take photos of meter and seals
6. **OCR**: Point camera at meter display to auto-read values
7. **Save**: Save as draft or submit for upload

### Tips for Best OCR Results

- Ensure good lighting on the meter display
- Hold the camera steady and focus properly
- Keep the meter display clean and readable
- Position the camera straight (avoid angles)
- Wait for the green indicator before capturing

---

## Technical Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.0+ |
| Language | Dart 3.0+ |
| Database | SQLite (sqflite) |
| OCR Engine | Google ML Kit Text Recognition |
| Scanner | Mobile Scanner |
| State | Provider |
| UI | Material Design 3 |

---

## Permissions Explained

| Permission | Why We Need It |
|------------|----------------|
| **Camera** | To scan barcodes and capture meter photos for OCR |
| **Storage** | To save captured images locally |
| **Location** | To geotag meter installations (optional) |

---

## Support

For technical support or questions:

- **Company**: Oculin Tech BD Ltd (OTBL)
- **Email**: support@otbl.com
- **Phone**: Contact your supervisor

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | Feb 2026 | Initial release with OCR, barcode scanning, offline support |

---

## License

Copyright © 2026 Oculin Tech BD Ltd (OTBL). All rights reserved.

This application is proprietary software developed for OTBL meter management operations.

---

<p align="center">
  Made with ❤️ by <strong>OTBL Development Team</strong>
</p>
