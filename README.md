# 小小音樂屋 · Little Music

A separate Flutter children's music app, not TownPass.

## Downloads / 自動建置

[Latest successful three-platform builds](https://github.com/steventeng2022/download-music-app-lock/actions/workflows/build.yml?query=is%3Asuccess)

Every push to `feat/**` or `main`, pull request, and manual dispatch builds **three separate artifacts**: Android APK, website ZIP, and unsigned iOS IPA. Open a successful run and download the platform artifact at the bottom (GitHub sign-in and repository access may be required). Artifacts expire after 30 days. Each contains a checksum. The web artifact contains an inner ZIP; extract it and serve it over HTTP, not `file://`. The IPA contains `Payload/Runner.app` and **requires external Apple signing/provisioning before installation**. Android release-mode builds currently use a debug/test key, not production signing.

## Child playback rules

- One large Play/Pause button. The shelf is read-only, not a song picker.
- No next, previous, seeking, playback-rate, URL entry, file picker, or import controls.
- Playback is fixed at 1×; only the player's natural completion event advances the bundled order.
- Remote/headset skip, seek, speed, queue mutation, repeat/shuffle and external-media commands are explicitly ignored by the native audio handler.
- Reopening restores local track and position (saved once per second), paused; completing the library remains completed. There is no child-accessible replay/reset. An adult can clear application storage to start a fresh listening session.
- No animation; reduced-motion preferences need no special handling. Responsive scroll layout, large touch targets, semantic standard controls, Traditional Chinese labels.

This is an **application-level control restriction, not a device kiosk or security sandbox**. Device settings, clearing data/reinstalling, browser developer tools, OS/browser media manipulation, or modifying source can bypass restrictions. Web cannot prevent those operations. Progress persistence is best-effort local storage, not tamper-proof or cross-device. Native background audio is configured, but physical-device/lock-screen/headset behavior needs device testing.

## Real approved music

`assets/library.json` is the fixed allowlist and provenance manifest. One real MP3 was retrieved from the user-supplied public Drive folder after the user confirmed redistribution authorization. No synthetic/demo songs are included.

- 巧連智【唱唱跳跳】2025精選合輯（二） (one compilation file, not individually split songs)
- Source file ID: `1WobsuINwUngw_kGOC0iutS7Ksco83SZ9`
- Bytes: `25297570`
- SHA-256: `085ead8af41e60e01b9b4dea264c90728a5efd50dd4de7f712c05ba93073c4d6`

Add approved songs only as a developer/adult source update: bundle actual MP3 files, append manifest entries in approved playback order, update their bytes/hashes, test, and rebuild. There is no runtime network downloader or arbitrary import. An empty manifest shows an honest empty-library state.

## Develop / verify

Pinned Flutter **3.47.6**, Dart 3.13.5; JDK 17 for Android. Direct audio dependencies are pinned and `pubspec.lock` is committed.

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter build apk --release
flutter build web --release --base-href /
# macOS + Xcode only:
flutter build ios --release --no-codesign
```

Controller tests cover natural-completion-only advancement, duplicate completion protection, end-of-library behavior, empty library, fixed speed, restoration and restrictive platform commands. Widget tests cover Play/Pause-only controls and small-screen layout. Tests use an injected transport so native plugins do not replace actual controller behavior with mocked policy. CI compiles the same `lib/main.dart` for all platforms. A green build is not a claim of physical-device testing.

