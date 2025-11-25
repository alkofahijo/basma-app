Fastlane stub for basma_app

This folder contains a minimal `Fastfile` with two lanes:

- `fastlane android_release`
  - Builds an Android App Bundle using Gradle / Fastlane.
  - If `GOOGLE_PLAY_JSON` environment variable points to a Play Console service account JSON file, the lane will call `supply` to upload the bundle to the given track (default `internal`).

- `fastlane ios_release`
  - Builds an iOS IPA via `flutter build ipa` and will upload to TestFlight via `upload_to_testflight` if `APP_STORE_CONNECT_API_KEY` is set.

How to use (CI / locally):
1. Install fastlane (Ruby + bundler):
   - `gem install fastlane` or use `bundle` with a `Gemfile`.
2. Set the required environment variables in CI or locally:
   - `GOOGLE_PLAY_JSON` = path to the base64-decoded Play service account json (or set `GOOGLE_PLAY_JSON` to file path in CI)
   - `APP_STORE_CONNECT_API_KEY` = path to App Store Connect API key JSON (or configure fastlane match/pilot credentials)
3. Run the lane:
   - `cd FrontEnd/basma_app`
   - `fastlane android_release` or `fastlane ios_release`

Notes & Security:
- Do NOT commit app store or keystore secrets. Use CI secrets and reference them in your workflows.
- On macOS runners you can run iOS lanes; on Linux/Windows only Android lanes will work.
- For Play Store uploads, ensure your service account has permissions for the Play Console and that the package name (`applicationId`) matches the app in the Play Console.
