# Zion API

Zion API is an Android-native API surface owned by Zion OS. It does not require Termux or a Termux API application.

## Architecture

Flutter/Dart
→ zion.os/api MethodChannel
→ ZionApiChannel.kt
→ Android framework APIs

CLI commands in Zion Userland use the same native implementation through the explicit com.zion.os.ZION_API activity IPC bridge. The bridge writes a request result under:

/data/data/com.zion.os/files/usr/tmp/zion-api-results/

The CLI waits for the native result and reports UNAVAILABLE or PERMISSION_REQUIRED instead of fabricating a success.

## Commands

### Device
- zion-api-battery
- zion-api-device-info
- zion-api-wifi-info
- zion-api-sensor [androidSensorType]

### Camera and media
- zion-api-camera-photo
- zion-api-camera-info
- zion-api-media-player <path> [mime]
- zion-api-audio-record [start|stop]

### Location
- zion-api-location
- zion-api-gps-status

### Notifications and UI
- zion-api-notification [title] [content]
- zion-api-toast <text>
- zion-api-dialog [title] [message]
- zion-api-vibrate [durationMs]
- zion-api-clipboard-get
- zion-api-clipboard-set <text>

### Audio
- zion-api-tts-speak <text>
- zion-api-tts-stop

### Communication
- zion-api-sms-list
- zion-api-sms-send <number> <body>
- zion-api-call <number>
- zion-api-contacts-list

### Storage
- zion-setup-storage
- zion-api-storage-get
- zion-api-file-share <path> [mime]

### Security
- zion-api-fingerprint
- zion-api-keystore [alias]

### System
- zion-api-wake-lock
- zion-api-wake-unlock
- zion-api-job-scheduler [jobId] [delayMs]
- zion-api-brightness <0..255>

## Security and audit

Native calls are reported to the Dart SecurityCore audit bridge. Terminal execution remains gated by the existing SecurityCore authorization path.

No API claims availability when the required Android capability, permission, hardware, or compatible application is absent.
