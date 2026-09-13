# ConnectCall

**Connect with anyone, anywhere.**

A 1-to-1 audio and video calling app built with Flutter for a Flutter Development Intern take-home assignment.

---

## Project description

ConnectCall is a real, working calling app — not a UI prototype. Users create an account, see a live directory of other users with online/offline presence, and start 1-to-1 audio or video calls that ring the other person, can be accepted or declined, and are recorded to both participants' call history once they end. Authentication and the user directory run on Firebase; the calls themselves run on ZEGOCLOUD.

## Features

**Core**
- Email/password sign up, sign in, and sign out (real Firebase Authentication, not mocked)
- Realtime user directory with search by name/email and live online/offline presence
- Profile screen (avatar, name, email, online status) and an edit-profile flow
- 1-to-1 audio calls and 1-to-1 video calls, with an incoming-call screen (ringing animation, Accept/Decline)
- In-call controls: Mute/Speaker/End on audio, Mute/Camera on-off/Switch camera/End on video
- Full call-state handling: `idle → calling → ringing → connected → inCall → ended`, plus `rejected`, `missed`, `busy`, `failed`, and `disconnected`
- Call history, recorded for **both** participants, with type, direction, status, and duration; previewed on the Home tab and listed in full under Calls
- Microphone/camera permission requests before every call, with denied vs. permanently-denied handling (the latter deep-links to system settings)
- User-facing error handling for a dead signaling connection vs. an unreachable peer, and empty/loading/error states across the directory and history lists

**Bonus implemented**
- Dark Mode — a persisted, user-togglable theme (switch lives on the Profile screen), solid white in light mode / solid black in dark mode

**Not implemented / partial** (see Known limitations)
- Background push notifications for incoming calls
- Group calling, screen sharing, call recording, a network-quality indicator, blocking a user, and a dedicated "frequent contacts" view

## Flutter & Dart version

Not pinned here — match whatever's declared in this project's `pubspec.yaml` (that file wasn't part of what generated this README). Run `flutter --version` in the project root to confirm what you're building with before submitting.

## Packages used

| Package | Used for |
|---|---|
| `firebase_core` | Firebase app initialization |
| `firebase_auth` | Email/password authentication |
| `cloud_firestore` | User directory, presence, and call history |
| `firebase_messaging` | Notification permission + FCM token capture |
| `provider` | State management (ChangeNotifier providers) |
| `zego_uikit_prebuilt_call` | The actual audio/video call surface (media engine + UI) |
| `zego_uikit_signaling_plugin` | Call invitations — ring, accept, reject, cancel, timeout |
| `zego_uikit` | Shared engine handle used to mirror mute/camera/speaker into the call UI |
| `permission_handler` | Microphone/camera permission requests + Settings deep-link |
| `shared_preferences` | Persists the Dark Mode choice across restarts |
| `cached_network_image` | Avatar/profile photo loading and caching |
| `intl` | Date/time formatting for call history and durations |

## Architecture

```
lib/
├── core/
│   ├── constants/app_constants.dart   # routes, Firestore collection names, Zego credentials
│   ├── theme/app_theme.dart           # light/dark ThemeData, design tokens
│   └── utils/
│       ├── permission_helper.dart
│       └── time_utils.dart
├── models/
│   ├── call_model.dart                # CallModel (Firestore) + CallSession (in-memory)
│   └── user_model.dart
├── services/            # thin wrappers directly over Firebase/Zego SDKs
│   ├── auth_service.dart
│   ├── calling_service.dart           # singleton wrapping ZegoUIKitPrebuiltCallInvitationService
│   ├── history_service.dart
│   └── user_service.dart
├── providers/            # ChangeNotifier state exposed to the UI via Provider
│   ├── auth_provider.dart
│   ├── call_provider.dart             # the call state machine + media controls
│   ├── theme_provider.dart
│   └── users_provider.dart
├── screens/
│   ├── splash/, auth/, home/, contacts/, profile/, call/, history/
├── widgets/
│   ├── brand_mark.dart, call_button.dart, call_history_row.dart,
│   │   common_button.dart, user_tile.dart
└── main.dart
```

**Why this split:** `services/` never touches `ChangeNotifier` — each one only knows how to talk to its SDK (Firebase or Zego). `providers/` hold the actual app state and business logic, and are the only layer the UI talks to (via `context.watch`/`context.read`). That keeps a screen from ever calling Firebase or Zego directly, which is what makes the call-state machine in `CallProvider` testable and easy to reason about in isolation.

**Why Provider:** the app's state is a handful of independent, moderately-sized concerns (auth, the user directory, the active call, theme) — Provider's `ChangeNotifier` pattern covers that without the extra ceremony of Bloc/Riverpod, and it's straightforward to explain and trace in a review.

## Backend

**Firebase** — Authentication (email/password) + Cloud Firestore.

```
users/{uid}
  uid, name, email, photoUrl, isOnline, lastSeen, fcmToken, createdAt

users/{uid}/call_history/{callId}
  peerId, peerName, peerPhoto, type ("audio" | "video"),
  direction ("incoming" | "outgoing"),
  status ("completed" | "missed" | "rejected" | "failed"),
  startedAt, durationSec
```

Call history is a **subcollection under each user**, and every finished call is written once for the caller and once for the callee (`HistoryService.saveCallForBoth`) — so each person only ever reads their own history, rather than everyone reading from one shared `calls` collection. Firestore is not used for call signaling at all; that's handled entirely by ZegoCloud (below).

## Calling — ZEGOCLOUD

**Why ZegoCloud:** its prebuilt call package (`zego_uikit_prebuilt_call`) bundles the media engine *and* the invitation/signaling logic (ringing, accept, reject, cancel, timeout, busy-detection) in one SDK, so the app doesn't need to hand-roll signaling over Firestore or run a separate server. Authentication is App ID + App Sign, which is enough for a project at this stage — no token server required.

**How the custom UI fits over the prebuilt widget:** `ZegoUIKitPrebuiltCall`'s own toolbar is hidden (`topMenuBar`/`bottomMenuBar` set to not visible) on both the audio and video screens. The visible Mute/Speaker/Camera/Switch/End row is our own `CallButton` widgets, wired through `CallProvider`, which mirrors every toggle into the Zego engine (`ZegoUIKit().turnMicrophoneOn(...)`, `turnCameraOn(...)`, `setAudioOutputToSpeaker(...)`) — so the on-screen design matches the approved mockups while Zego still owns the actual media.

**Call lifecycle:** `CallProvider` drives `idle → calling → ringing → connected → inCall → ended`, wired to Zego's invitation events (`onIncomingCallReceived`, `onOutgoingCallAccepted`, `onOutgoingCallDeclined`, `onOutgoingCallRejectedCauseBusy`, `onIncomingCallTimeout`/`onOutgoingCallTimeout`) and the call widget's own `onCallEnd`/`user.onEnter`. Every terminal path — reject, cancel, busy, timeout, remote hang-up — writes a call-history record before returning to `idle`, so history is complete even for calls that never connect.

## Permissions & error handling

- Microphone (and camera, for video) permission is requested before every outgoing or accepted call. Granted → proceed; denied → a retry-friendly message; permanently denied → a dialog offering to open system Settings.
- `CallingService` distinguishes two failure modes with dedicated exceptions: `SignalingOfflineException` (our own connection to Zego is down — an internet/reconnect problem) and `PeerUnreachableException` (the invitation couldn't be delivered — the peer needs the app open). Both surface as a plain-language SnackBar rather than a stack trace.
- Directory and history screens each have distinct loading, error (with Retry), and empty states.

## Setup instructions

1. Install Flutter (match the SDK constraint in `pubspec.yaml`) and run `flutter pub get`.
2. **Firebase** — create a project in the Firebase console, enable Email/Password sign-in, create a Firestore database, then from the project root run:
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Select the platforms you're targeting; this regenerates `lib/firebase_options.dart`.
3. **ZEGOCLOUD** — create a project at the ZEGOCLOUD Console and copy its App ID and App Sign into `ZEGO_APP_ID` / `ZEGO_APP_SIGN` in `lib/core/constants/app_constants.dart`.
4. **Platform permissions** — confirm microphone (and camera, for video) usage descriptions are present in `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist` (`NSMicrophoneUsageDescription`, `NSCameraUsageDescription`).
5. `flutter run` to launch, or `flutter build apk --release` to produce the submission APK.

## Configuration

- `lib/firebase_options.dart` — generated per-platform by `flutterfire configure`; regenerate against your own Firebase project rather than reusing a committed copy.
- `lib/core/constants/app_constants.dart` — holds `ZEGO_APP_ID` and `ZEGO_APP_SIGN`. Treat both as configuration to set per-environment rather than commit as-is if this repo is public.

## Known limitations

- The audio-call and incoming-call screens use whichever theme (light/dark) is currently active, so they appear on a white background in Light Mode. `AppTheme` defines a `callBackground`/`callForeground` token intended to force calls dark in every mode, but it isn't wired into those screens' `Scaffold` yet. The video-call screen isn't affected, since the live camera feed fills the frame regardless.
- Edit Profile currently saves only the display name. The Email and Phone fields are shown and editable but aren't persisted — `UserModel` has no `phone` field at all yet.
- Changing the profile photo is done by pasting an image URL, not by picking from the camera/gallery or uploading to storage.
- "Forgot password?" on Login and the settings-gear icon on Profile are placeholders with no action wired up yet.
- Push notifications are partially in place: permission is requested and an FCM token is stored per user, but there's no server-side trigger yet to deliver a call notification while the app is fully closed. While the app is open or backgrounded-but-alive, Zego's own signaling connection is what actually rings the callee.
- Online/offline status is Firestore presence, which can momentarily drift from whether the peer's device is truly reachable on Zego's signaling channel at that instant.
- No automated tests yet.

## AI tools used

Claude (Anthropic) was used for architecture and tech-stack decisions (Provider + Firebase + ZegoCloud), for writing the structured prompts used to drive AI-assisted implementation of the app and its UI, for turning the approved mockups into a visual design spec, and for this README.

*If a separate AI coding tool (e.g. Cursor, GitHub Copilot, ChatGPT) was used to generate or edit the Dart code itself, name it here — that wasn't run in the same session this document was written in, so it isn't reflected above.*

## Demo

*Add the link to your walkthrough video here before submitting (login → user list → audio call → receive/accept → mute/unmute → end → video call → camera controls → call history).*