# Standard Operating Procedure (SOP)
## CMO Meter OCR App - User Manual

**Document Version**: 1.0
**Effective Date**: February 2026
**Prepared By**: OTBL Development Team
**Approved By**: OTBL Management

---

## Table of Contents

1. [Purpose](#1-purpose)
2. [Scope](#2-scope)
3. [Definitions](#3-definitions)
4. [Responsibilities](#4-responsibilities)
5. [Procedure](#5-procedure)
6. [Troubleshooting](#6-troubleshooting)
7. [Safety & Security](#7-safety--security)
8. [References](#8-references)

---

## 1. Purpose

This Standard Operating Procedure (SOP) provides step-by-step instructions for using the **CMO Meter OCR App** to:
- Record new meter installations
- Process Change Meter Owner (CMO) requests
- Capture meter readings using OCR technology
- Manage offline data collection in the field

---

## 2. Scope

This SOP applies to:
- Field technicians performing meter installations
- CMO processing officers
- Supervisors overseeing meter management operations
- IT support staff maintaining the application

---

## 3. Definitions

| Term | Definition |
|------|------------|
| **CMO** | Change Meter Owner - Process of transferring meter ownership |
| **OCR** | Optical Character Recognition - Technology to read text from images |
| **NID** | National ID Number |
| **NOCS** | Number of Consumer Serial |
| **Draft** | CMO request saved locally but not submitted |
| **Pending** | CMO request ready for upload |
| **Uploaded** | CMO request successfully synced to server |

---

## 4. Responsibilities

### 4.1 Field Technicians
- Install the app on assigned mobile devices
- Collect accurate customer and meter information
- Capture clear photos of meters and seals
- Sync data when internet is available

### 4.2 Supervisors
- Monitor CMO request status
- Review and approve submitted requests
- Ensure data quality and completeness

### 4.3 IT Support
- Provide technical assistance
- Manage app updates and deployments
- Handle data backup and recovery

---

## 5. Procedure

### 5.1 App Installation

**Step 1**: Download the APK
1. Obtain the APK file from IT department or download link
2. Transfer to mobile device if needed

**Step 2**: Install the App
1. Open device Settings → Security
2. Enable "Install from Unknown Sources"
3. Navigate to the APK file and tap to install
4. Wait for installation to complete
5. Tap "Open" to launch the app

**Step 3**: First Launch Setup
1. Grant required permissions when prompted:
   - Camera (Required)
   - Storage (Required)
   - Location (Optional)

---

### 5.2 User Registration

**Step 1**: Open the App
1. Launch CMO Meter OCR App
2. On the login screen, tap "Register"

**Step 2**: Enter Registration Details
1. Full Name: Enter your complete name
2. Email: Enter a valid email address
3. Password: Create a strong password (minimum 6 characters)
4. Confirm Password: Re-enter the password

**Step 3**: Complete Registration
1. Tap "Register" button
2. Wait for confirmation message
3. You will be redirected to login screen

---

### 5.3 User Login

1. Enter your registered email
2. Enter your password
3. Tap "Login" button
4. You will be directed to the Home Dashboard

---

### 5.4 Creating a New CMO Request

#### Step 1: Start New CMO
1. From Home Dashboard, tap the **"+"** button
2. Or tap "CMO" menu → "Add New CMO"

#### Step 2: Customer Information
Fill in the following fields:

| Field | Description | Required |
|-------|-------------|----------|
| Customer Name | Full name of the meter owner | Yes |
| Mobile Number | 11-digit mobile number | Yes |
| Email | Customer email address | No |
| NID | National ID number | Yes |
| NOCS | Number of Consumer Serial | Yes |
| Address | Installation address | Yes |

Tap **"Next"** to continue.

#### Step 3: Meter Information
1. **Customer ID**:
   - Tap the barcode icon to scan, OR
   - Enter manually

2. **New Meter ID**:
   - Tap the barcode icon to scan, OR
   - Enter manually

3. **Meter Reading** (OCR):
   - Tap "Capture Meter Reading"
   - Point camera at meter display
   - Wait for OCR to detect numbers
   - Verify the reading and confirm

Tap **"Next"** to continue.

#### Step 4: Old Meter Information
1. **Old Meter ID**: Enter or scan the old meter ID
2. **Old Meter Reading**: Enter the final reading
3. **Old Meter Photo**:
   - Tap "Capture Photo"
   - Take a clear photo of the old meter
   - Review and confirm

Tap **"Next"** to continue.

#### Step 5: Seal Information
Record all seal numbers:

| Seal Type | Description |
|-----------|-------------|
| Battery Cover Seal | Seal on battery compartment |
| Terminal Seal A | First terminal seal |
| Terminal Seal B | Second terminal seal |
| Terminal Seal C | Third terminal seal |

For each seal:
1. Enter seal number manually, OR
2. Tap barcode icon to scan
3. Tap "Capture Photo" to photograph the seal

Tap **"Next"** to continue.

#### Step 6: Installation Details
1. **Installation Date**: Select the date
2. **Installer Name**: Enter your name or ID
3. **Steel Box**: Select Yes/No if steel box is installed
4. **Remarks**: Add any additional notes

#### Step 7: Save CMO Request
Choose one option:

| Option | Description |
|--------|-------------|
| **Save as Draft** | Save locally for later editing |
| **Submit** | Mark as ready for upload |

---

### 5.5 Using OCR for Meter Reading

**Best Practices for Accurate OCR:**

1. **Lighting**
   - Ensure adequate lighting on the meter display
   - Avoid shadows on the display
   - Use flash if needed in dark conditions

2. **Camera Position**
   - Hold device parallel to meter display
   - Keep distance of 15-30 cm
   - Ensure display fills most of the frame

3. **Focus**
   - Wait for auto-focus to complete
   - Numbers should be sharp and clear
   - Tap screen to refocus if needed

4. **Capture**
   - Hold steady when capturing
   - Wait for green indicator
   - Review captured reading
   - Retake if reading is incorrect

---

### 5.6 Using Barcode Scanner

1. Tap the barcode/scan icon next to the field
2. Point camera at the barcode
3. Hold steady until barcode is detected
4. Scanner will automatically capture and fill the field
5. Verify the scanned value is correct

**Tips:**
- Ensure barcode is not damaged or faded
- Good lighting improves scan speed
- Hold camera 10-20 cm from barcode

---

### 5.7 Managing CMO Requests

#### View All CMOs
1. From Home, tap "CMO" menu
2. View list of all CMO requests
3. Filter by status: Draft, Pending, Uploaded

#### Edit a Draft CMO
1. Find the CMO in the list
2. Tap on the CMO card
3. Tap "Edit" button
4. Make necessary changes
5. Save changes

#### Delete a CMO
1. Find the CMO in the list
2. Tap on the CMO card
3. Tap "Delete" button
4. Confirm deletion

**Warning**: Deleted CMOs cannot be recovered!

#### Search CMOs
1. Tap the search icon
2. Enter search term:
   - Customer name
   - Customer ID
   - Mobile number
   - Meter ID
3. View matching results

---

### 5.8 Data Synchronization

#### Automatic Sync
- App automatically syncs when internet is available
- Look for sync icon in status bar

#### Manual Sync
1. Go to Settings
2. Tap "Sync Now"
3. Wait for sync to complete
4. Check for success message

#### Sync Status Indicators

| Status | Meaning |
|--------|---------|
| Green checkmark | Successfully uploaded |
| Yellow clock | Pending upload |
| Grey draft | Saved as draft |
| Red exclamation | Sync failed - retry needed |

---

### 5.9 Offline Usage

The app works completely offline:

1. **Data Entry**: All forms work without internet
2. **Photos**: Saved locally on device
3. **Database**: SQLite stores all records
4. **Sync Later**: Upload when connected

**Important**:
- Regularly sync when internet is available
- Backup device data periodically
- Don't uninstall app without syncing

---

## 6. Troubleshooting

### 6.1 Common Issues

| Issue | Solution |
|-------|----------|
| Camera not working | Check camera permission in Settings |
| OCR not detecting numbers | Ensure good lighting and focus |
| Barcode not scanning | Clean barcode, improve lighting |
| App crashing | Clear app cache, restart device |
| Login failed | Check email and password, reset if needed |
| Sync failed | Check internet connection, retry |
| Photos not saving | Check storage permission, free up space |

### 6.2 Error Messages

| Error | Meaning | Action |
|-------|---------|--------|
| "Camera permission denied" | Camera access not granted | Go to Settings → Apps → CMO App → Permissions → Enable Camera |
| "Storage full" | Device storage is full | Delete unnecessary files or photos |
| "Network error" | No internet connection | Connect to WiFi or mobile data |
| "Invalid credentials" | Wrong email or password | Check credentials or reset password |
| "Database error" | Local database issue | Clear app data and re-login |

### 6.3 Contact Support

If issues persist:
1. Note the error message
2. Take a screenshot if possible
3. Contact IT Support with details
4. Provide device model and app version

---

## 7. Safety & Security

### 7.1 Data Security
- All passwords are encrypted
- Local data is stored securely
- Photos are stored in private app directory

### 7.2 User Responsibilities
- Do not share login credentials
- Log out when not using the app
- Report lost/stolen devices immediately
- Do not install on personal devices without approval

### 7.3 Privacy
- Customer data must be handled confidentially
- Do not share customer information
- Photos should only contain relevant meter/seal images
- Avoid capturing personal items in photos

---

## 8. References

- CMO Meter OCR App User Interface
- OTBL Data Management Policy
- Field Operations Guidelines
- IT Security Policy

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Feb 2026 | OTBL Dev Team | Initial release |

---

## Appendix A: Quick Reference Card

### Daily Workflow Checklist

- [ ] Charge device fully before field work
- [ ] Ensure app is updated to latest version
- [ ] Log in to the app
- [ ] Verify camera and scanner are working
- [ ] Complete assigned CMO requests
- [ ] Take clear photos of all meters and seals
- [ ] Save CMOs as you complete them
- [ ] Sync data when internet is available
- [ ] Log out at end of day

### Keyboard Shortcuts

| Action | Method |
|--------|--------|
| Quick scan | Tap barcode icon |
| Take photo | Tap camera icon |
| OCR reading | Tap OCR button |
| Save draft | Swipe down on form |
| Submit | Tap Submit button |

---

**Document Control**
This document is controlled by OTBL IT Department.
Unauthorized reproduction is prohibited.

© 2026 Oculin Tech BD Ltd. All Rights Reserved.
