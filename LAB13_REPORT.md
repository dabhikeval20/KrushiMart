# KrushiMart App - Lab Report (LAB 13)

## Preparing Release Build (APK/AAB)

## Student Information
- **Name**: [Your Name]
- **Roll Number**: [Your Roll Number]
- **Course**: Mobile Application Development (MAD)
- **Semester**: 6
- **Subject**: Flutter Development

## 1. Aim
To prepare the KrushiMart mobile application for production release by configuring app icon, splash screen, versioning, permissions, and generating release builds (APK/AAB) for distribution.

## 2. Introduction
Release preparation is the final step in mobile app development where the application is configured for production deployment. This includes setting up professional branding (icon, splash screen), proper permissions, versioning, and generating optimized build files for distribution through app stores.

For KrushiMart, this involves:
- Professional app icon and splash screen
- Proper Android permissions for camera, storage, internet, and notifications
- Version management for updates
- Release build generation for Google Play Store

## 3. App Icon Configuration

### Using flutter_launcher_icons Package

#### Step 1: Add Dependency
Add to `pubspec.yaml` in dev_dependencies:
```yaml
dev_dependencies:
  flutter_launcher_icons: "^0.13.1"
```

#### Step 2: Configure Icon in pubspec.yaml
```yaml
flutter_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icon/app_icon.png"
  min_sdk_android: 21 # android min sdk min:16, default 21
  web:
    generate: true
    image_path: "assets/icon/app_icon.png"
    background_color: "#hexcode"
    theme_color: "#hexcode"
  windows:
    generate: true
    image_path: "assets/icon/app_icon.png"
    icon_size: 48 # min:48, max:256, default: 48
```

#### Step 3: Create Icon Asset
- Create `assets/icon/` directory
- Place `app_icon.png` (1024x1024 recommended) in the directory

#### Step 4: Generate Icons
Run the following command:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

#### Expected Output
```
✓ Successfully generated launcher icons
```

This generates icons for Android, iOS, Web, and Windows platforms automatically.

## 4. Splash Screen Configuration

### Using flutter_native_splash Package

#### Step 1: Add Dependency
Add to `pubspec.yaml` in dev_dependencies:
```yaml
dev_dependencies:
  flutter_native_splash: "^2.3.0"
```

#### Step 2: Configure Splash Screen in pubspec.yaml
```yaml
flutter_native_splash:
  color: "#2E7D32"  # Background color
  image: assets/images/splash_logo.png  # Logo image

  # Android specific
  android_12:
    image: assets/images/splash_logo.png
    color: "#2E7D32"

  # iOS specific
  ios_content_mode: center

  # Web specific
  web_image_mode: center

  # General
  fullscreen: true
```

#### Step 3: Create Splash Assets
- Create `assets/images/` directory
- Place `splash_logo.png` (transparent PNG recommended)

#### Step 4: Generate Splash Screen
Run the following command:
```bash
flutter pub get
flutter pub run flutter_native_splash:create
```

#### Expected Output
```
✓ Android splash screen generated successfully
✓ iOS splash screen generated successfully
✓ Web splash screen generated successfully
```

## 5. Versioning

### Version Format Explanation
Flutter uses semantic versioning: `major.minor.patch+build`

- **major**: Breaking changes
- **minor**: New features (backward compatible)
- **patch**: Bug fixes
- **build**: Internal build number

Example: `version: 1.0.0+1`

### How to Update Version
1. **Edit pubspec.yaml**:
   ```yaml
   version: 1.2.0+2  # Increment version
   ```

2. **Override in build command** (optional):
   ```bash
   flutter build apk --build-name=1.2.0 --build-number=2
   ```

3. **Android Impact**:
   - versionName = build-name (1.2.0)
   - versionCode = build-number (2)

4. **iOS Impact**:
   - CFBundleShortVersionString = build-name
   - CFBundleVersion = build-number

## 6. Android Permissions

### Required Permissions for KrushiMart

#### AndroidManifest.xml Configuration
Add the following permissions inside `<manifest>` tag:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Internet permission for API calls -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <!-- Camera permission for image capture -->
    <uses-permission android:name="android.permission.CAMERA" />

    <!-- Storage permissions for image gallery access -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

    <!-- Notification permissions -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.VIBRATE" />

    <!-- Wake lock for notifications -->
    <uses-permission android:name="android.permission.WAKE_LOCK" />

    <!-- Firebase messaging -->
    <uses-permission android:name="com.google.android.c2dm.permission.RECEIVE" />

    <application>
        <!-- ... existing application config ... -->

        <!-- Firebase messaging service -->
        <service
            android:name=".java.MyFirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>

    </application>
</manifest>
```

### Permission Explanations
- **INTERNET**: Required for API calls to FakeStore API and Firebase
- **CAMERA**: Allows image capture for product photos
- **READ_EXTERNAL_STORAGE**: Access gallery images
- **WRITE_EXTERNAL_STORAGE**: Save images temporarily
- **POST_NOTIFICATIONS**: Display local and push notifications
- **WAKE_LOCK**: Keep device awake for notifications

## 7. Generate Release Build

### Prerequisites
1. **Clean project**:
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Check for errors**:
   ```bash
   flutter analyze
   flutter doctor
   ```

### Generate APK (Android Package)
```bash
flutter build apk --release
```

**Expected Output**:
```
✓ Built build/app/outputs/flutter-apk/app-release.apk (12.3MB)
```

**Location**: `build/app/outputs/flutter-apk/app-release.apk`

### Generate AAB (Android App Bundle)
```bash
flutter build appbundle --release
```

**Expected Output**:
```
✓ Built build/app/outputs/bundle/release/app-release.aab (8.7MB)
```

**Location**: `build/app/outputs/bundle/release/app-release.aab`

### APK vs AAB Difference

| Feature | APK | AAB |
|---------|-----|-----|
| **Size** | Larger (includes all resources) | Smaller (dynamic delivery) |
| **Google Play** | Supported but less efficient | Recommended by Google |
| **Dynamic Delivery** | No | Yes (splits by device) |
| **Update Size** | Full app update | Only changed modules |
| **Distribution** | Direct install, sideloading | Google Play only |
| **File Size** | ~12-15MB | ~8-12MB |

## 8. Testing Release Build

### Install APK on Real Device

#### Method 1: USB Connection
```bash
# Connect device via USB
adb devices  # Check connection

# Install APK
flutter install --release
```

#### Method 2: Direct APK Install
1. Transfer `app-release.apk` to device
2. Enable "Install from unknown sources" in settings
3. Tap APK file to install

#### Method 3: Google Play Internal Testing
1. Upload AAB to Google Play Console
2. Create internal test track
3. Add tester emails
4. Share download link

### Testing Checklist

#### 1. Installation Test
- [ ] APK installs successfully
- [ ] App icon appears on home screen
- [ ] Splash screen displays correctly
- [ ] App launches without crash

#### 2. Authentication Test
- [ ] User registration works
- [ ] Login with valid credentials
- [ ] Role-based navigation (Buyer/Seller)
- [ ] Session persistence

#### 3. CRUD Operations Test
- [ ] Add product with image (Seller)
- [ ] Edit product details
- [ ] Delete product confirmation
- [ ] Product list refresh

#### 4. API Integration Test
- [ ] FakeStore API products load
- [ ] Product search/filter works
- [ ] Error handling for no internet
- [ ] Loading states display

#### 5. Notifications Test
- [ ] Local notifications trigger
- [ ] Push notifications received
- [ ] Notification deep linking
- [ ] Scheduled reminders work

#### 6. Image Upload Test
- [ ] Camera capture works
- [ ] Gallery selection works
- [ ] Image upload to Firebase
- [ ] Image preview displays

#### 7. UI/UX Test
- [ ] Layout responsive on device
- [ ] Buttons functional
- [ ] Text readable
- [ ] No UI overflow

#### 8. Performance Test
- [ ] App startup time < 3 seconds
- [ ] Image loading smooth
- [ ] No memory leaks
- [ ] Battery usage reasonable

## 9. Expected Outcome
- **Professional App**: Custom icon and splash screen
- **Proper Permissions**: All required Android permissions configured
- **Optimized Build**: Release APK/AAB generated successfully
- **Production Ready**: App tested on real device with all features working
- **Store Ready**: Files prepared for Google Play Store submission

## 10. Conclusion
Release build preparation is crucial for transforming a development app into a production-ready application. Through proper configuration of icons, splash screens, permissions, and versioning, KrushiMart is now prepared for distribution.

The release build process ensures:
- Professional branding and user experience
- Proper platform permissions and security
- Optimized file sizes for distribution
- Thorough testing on real devices

Key learnings from this lab:
- Importance of proper app branding
- Android permission management
- Difference between APK and AAB formats
- Release build optimization
- Real device testing procedures

The KrushiMart app is now ready for Google Play Store submission and user distribution.

---

**Declaration**: I hereby declare that the release build preparation activities described above were conducted thoroughly and the KrushiMart app is ready for production deployment.

**Date**: April 7, 2026  
**Signature**: ___________________________