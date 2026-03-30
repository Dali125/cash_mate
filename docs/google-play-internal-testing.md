# Google Play Internal Testing

This project is close to ready for Google Play internal testing, but these items still need to be completed before upload:

1. Confirm the final Android package name.
   This project currently uses `com.spaceinvaders.cashmate`.
   If you want a different package name, update:
   - `android/app/build.gradle`
   - `android/app/src/main/kotlin/com/spaceinvaders/cashmate/MainActivity.kt`
   - the folder path `android/app/src/main/kotlin/com/spaceinvaders/cashmate/`

2. Create an upload keystore.
   Example:

   ```bash
   keytool -genkeypair -v \
     -keystore android/app/upload-keystore.jks \
     -alias upload \
     -keyalg RSA \
     -keysize 2048 \
     -validity 10000
   ```

3. Create `android/key.properties` from `android/key.properties.example`.

4. Increase the Android version before each upload.
   Update `version:` in `pubspec.yaml`. Google Play requires a new build number every time.

5. Build the release bundle.

   ```bash
   flutter build appbundle
   ```

6. Upload the generated bundle from `build/app/outputs/bundle/release/app-release.aab` to the Google Play Console Internal testing track.

## Play Console note

The broad storage permissions were removed from `android/app/src/main/AndroidManifest.xml` to avoid the `MANAGE_EXTERNAL_STORAGE` policy risk.
