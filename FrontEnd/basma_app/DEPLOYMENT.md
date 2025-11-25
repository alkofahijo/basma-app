# Mobile Deployment Checklist

This document lists the manual and project changes needed to prepare the Flutter app for Play Store and App Store releases.

## Environment & Build
- Use compile-time defines to select environment:
  - Example: `flutter build apk --release --dart-define=ENV=prod`
  - For debug/dev: `--dart-define=ENV=dev` or omit (defaults to `dev`).
- The app reads the base URL from `lib/config/env.dart` via `kBaseUrl` in `lib/config/base_url.dart`.

## Android (Play Store)
- Update `android/app/build.gradle.kts`:
  - Set `applicationId` to your app id (e.g. `com.yourcompany.basma_app`).
  - Update `versionCode` and `versionName`.
- Update `android/app/src/main/AndroidManifest.xml` if additional permissions or intent-filters are required.
- App icons:
  - Replace launcher icons under `android/app/src/main/res/mipmap-*` or use `flutter_launcher_icons`.
- Signing (manual step):
  - Generate a release keystore: `keytool -genkey -v -keystore release.keystore -alias basma_key -keyalg RSA -keysize 2048 -validity 10000`
  - Place the keystore securely and add `key.properties` with path/password (do NOT commit secrets).
  - Configure signing in `android/app/build.gradle.kts`.
- Build release APK/AAB:
  - `flutter build appbundle --release --dart-define=ENV=prod`
- Upload to Play Console and fill store listing, screenshots, privacy policy.

## iOS (App Store)
- Update bundle identifier in Xcode (`ios/Runner.xcodeproj`) to your app id.
- Update `CFBundleShortVersionString` and `CFBundleVersion` in `ios/Runner/Info.plist`.
- App icons:
  - Replace images in `ios/Runner/Assets.xcassets/AppIcon.appiconset`.
- Code signing & provisioning (manual steps in Apple Developer portal/Xcode):
  - Create App ID and provisioning profile, configure certificates.
  - In Xcode, select your team and profile for release.
- Build archive and upload via Xcode or `xcrun`.

## CI / Secrets
- Store keystore passwords, upload keys, Apple provisioning profiles, and Play Console service account keys in your CI secret store (GitHub Actions secrets, Azure DevOps, etc.).
- Do NOT commit keystore files/passwords to VCS.

## Tips
- Test release build locally before upload: install the APK on a device or test TestFlight for iOS.
- Keep `ENV` builds reproducible by using CI with `--dart-define` flags.

## Example Build Commands
- Android AAB (prod):
  - `flutter build appbundle --release --dart-define=ENV=prod`
- iOS archive (prod):
  - Configure Xcode signing then `flutter build ipa --release --dart-define=ENV=prod`

If you want, I can:
- Add Gradle signing snippets to `android/app/build.gradle.kts` (placeholders, non-secret),
- Add a `fastlane` or CI example for automating builds,
- Or run a quick search to ensure all references to `kBaseUrl` use the centralized config.
