# Android signing and release

This project includes a minimal signing scaffold.

Steps to prepare a release build:

1. Create a release keystore (if you don't have one):

```powershell
keytool -genkey -v -keystore C:\path\to\release.jks -alias your_alias -keyalg RSA -keysize 2048 -validity 10000
```

2. Copy `key.properties.template` to `android/key.properties` and fill the values (DO NOT commit this file):

```
storeFile=C:\path\to\release.jks
storePassword=your_store_password
keyAlias=your_alias
keyPassword=your_key_password
```

3. Build an Android App Bundle (recommended for Play Store):

```powershell
cd FrontEnd\basma_app
flutter build appbundle --release
```

Notes:
- `android/app/build.gradle.kts` will attempt to load `key.properties` and configure the `release` signingConfig automatically.
- If `key.properties` is missing, the build will fall back to the debug signing config (useful for local testing but not for Play Store submissions).
- Update `applicationId` in `android/app/build.gradle.kts` if you want a different package id. Currently it is set to `com.basma.volunteering`.
- After publishing, enroll in Google Play App Signing and keep a secure backup of the keystore.

CI / GitHub Actions snippet (example)
----------------------------------
This example shows how to build an Android App Bundle in CI using secrets to provide the keystore. It expects the following GitHub repository secrets to be set:

- `ANDROID_KEYSTORE_BASE64`: base64-encoded keystore binary
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- (optional) `GOOGLE_PLAY_JSON_KEY_BASE64`: base64 of the Play Console service account json for fastlane `supply`

Add a workflow file like `.github/workflows/android-release.yml` with the following (trimmed) steps:

```yaml
name: Android Release

on:
	workflow_dispatch: {}

jobs:
	build:
		runs-on: ubuntu-latest
		steps:
			- uses: actions/checkout@v4
			- name: Set up Java
				uses: actions/setup-java@v4
				with:
					distribution: 'temurin'
					java-version: '17'
			- name: Install Flutter
				uses: subosito/flutter-action@v2
				with:
					flutter-version: 'stable'

			# Restore keystore from secret
			- name: Restore keystore
				run: |
					echo "$ANDROID_KEYSTORE_BASE64" | base64 --decode > android/keystore.jks
					cat > android/key.properties <<EOF
					storeFile=android/keystore.jks
					storePassword=$ANDROID_KEYSTORE_PASSWORD
					keyAlias=$ANDROID_KEY_ALIAS
					keyPassword=$ANDROID_KEY_PASSWORD
					EOF
				env:
					ANDROID_KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
					ANDROID_KEYSTORE_PASSWORD: ${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
					ANDROID_KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
					ANDROID_KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}

			- name: Install dependencies
				run: flutter pub get

			- name: Build app bundle
				run: flutter build appbundle --release

			# Optional: upload with fastlane/supply (requires GOOGLE_PLAY_JSON_KEY_BASE64 secret)
			- name: Upload to Play (fastlane supply)
				if: env.GOOGLE_PLAY_JSON_KEY_BASE64 != ''
				run: |
					echo "$GOOGLE_PLAY_JSON_KEY_BASE64" | base64 --decode > /tmp/google-play.json
					bundle install --path vendor/bundle || true
					bundle exec fastlane android_release google_play_json:/tmp/google-play.json
				env:
					GOOGLE_PLAY_JSON_KEY_BASE64: ${{ secrets.GOOGLE_PLAY_JSON_KEY_BASE64 }}
```

Security notes:
- Never store keystore passwords in source. Use repository secrets or a secure secrets manager.
- The above writes the keystore to `android/keystore.jks` in the workspace — CI runners are ephemeral, so the file is not persisted.

Local testing tip
-----------------
If you want to test the release build locally, copy `key.properties.template` to `android/key.properties` and fill values, then run:

```powershell
cd FrontEnd\basma_app
flutter build appbundle --release
```

If you want me to add a ready-to-use `.github/workflows/android-release.yml` file in this repo, say so and I'll create it (it will reference secrets — do not commit secret values).
