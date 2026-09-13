# Connect Call — Connect with anyone, anywhere.

Production-ready Flutter 1-to-1 audio/video calling app.

**Stack (fixed):** Flutter 3.22+ / Dart 3 / Material 3 · `provider` only ·
`firebase_core`, `firebase_auth` (Email/Password), `cloud_firestore`,
`firebase_messaging` · `zego_uikit_prebuilt_call` +
`zego_uikit_signaling_plugin` · `permission_handler`, `intl`,
`cached_network_image`.

## 1. Firebase setup

1. Create a Firebase project at https://console.firebase.google.com.
2. Add Android app (`applicationId`, e.g. `com.example.connectcall`):
   - Download `google-services.json` → `android/app/google-services.json`.
   - Add Gradle plugin per FlutterFire docs (`flutterfire configure` recommended).
3. Add iOS app (bundle id) → `GoogleService-Info.plist` → `ios/Runner/`.
4. Enable **Authentication → Email/Password**.
5. Create **Firestore Database** (production mode) + rules (dev example):
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{db}/documents {
       match /users/{uid} {
         allow read: if request.auth != null;
         allow write: if request.auth != null && request.auth.uid == uid;
         match /call_history/{callId} {
           allow read, write: if request.auth != null &&
             (request.auth.uid == uid || true);
         }
       }
     }
   }
   ```
   Tighten history rules for production (only the two participants).
6. (Optional) Enable **Cloud Messaging** — FCM token is saved to
   `users/{uid}.fcmToken` for future offline-push.

No `firebase_options.dart` is committed — run
`flutterfire configure` to generate it, or rely on the native
`google-services.json` / `GoogleService-Info.plist`.

> ✅ Already done for Firebase project `connect--call1`:
> `lib/firebase_options.dart` generated for android, ios, macos, web,
> windows; `main.dart` uses
> `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`;
> `android/app/google-services.json` present. No
> `GoogleService-Info.plist` on ios/macos — not needed since options
> flow from Dart (Auth/Firestore/Messaging work without it).
> (Linux is not supported by FlutterFire — `DefaultFirebaseOptions`
> throws `UnsupportedError` there. To target Linux, add its config to
> `firebase_options.dart` manually or guard the `initializeApp` call.)

Firestore schema used:
```
users/{uid}: {uid, name, email, photoUrl, isOnline, lastSeen, fcmToken, createdAt}
users/{uid}/call_history/{callId}: {peerId, peerName, peerPhoto,
  type: audio|video, direction: incoming|outgoing,
  status: completed|missed|rejected|failed, startedAt, durationSec}
```

## 2. Zego setup

Credentials are baked in (`lib/core/constants/app_constants.dart`):
```dart
const int ZEGO_APP_ID = 1664373490;
const String ZEGO_APP_SIGN = "120eb6a56f8babab35b8347a1d27c5bf4397bdb6b00f1cc7645eb1207389ead5";
```

- Same AppID/Sign on **both** devices (already the case).
- Online 1-to-1 invitations work out of the box via
  `ZegoUIKitSignalingPlugin` (ZIM). No console push config needed for
  foreground/online calls.
- Offline / killed-app push requires a Zego `resourceID` + APNs/FCM
  certificate in the Zego console, then pass `resourceID` in
  `CallingService.sendCallInvitation`. Currently `resourceID` is omitted —
  offline invites will be missed (documented limitation).
- Zego `userID` = sanitized Firebase UID (alphanumeric, ≤32 chars);
  `callID` = `call_<ms>_<callerFrag>`, shared via invitation so both
  sides join the same room.

## 3. Run

```bash
cd connectcall
flutter pub get
flutter run            # two real devices / emulators, two accounts
flutter build apk --release
```

Supported devices/platforms: Android, iOS, Web, Windows, macOS, Linux
(scaffolded via `flutter create --platforms=web,windows,macos,linux`).
Real-time audio/video calling is fully supported on Android/iOS;
on Web/Desktop the app compiles and runs, but the Zego native calling
engine may have limited support — use an Android/iOS device for calls.

> Web + Dart 3.11 note (temporary, machine-local): `firebase_core_web`
> 3.11.0 (latest on pub.dev) uses `Object.isA()`, an API removed from
> Dart 3.11's `dart:js_interop`, so `flutter run -d chrome` /
> `flutter build web` failed to compile. Fixed locally by patching 2
> lines in the pub cache
> (`.../firebase_core_web-3.11.0/lib/src/firebase_core_web.dart`:
> `!e.isA<JSObject>()` → `e is! JSObject`). No other Firebase web
> package uses `isA` (verified). If `pub cache repair` or a fresh
> `pub get` on a new machine wipes the patch, re-apply it — or upgrade
> `firebase_core_web` once upstream ships a Dart 3.11-compatible release
> (`flutter pub upgrade firebase_core_web`, then rebuild web).

Checklist: launch OK · register/login/logout (presence flips
`isOnline`) · user list excludes me · audio start/receive/accept/reject/
mute/speaker/end · video start/camera toggle/switch/end · history for
**both** users · permissions (mic/camera, Open Settings on permanent
deny) · APK builds.

Permissions are declared in:
- `android/app/src/main/AndroidManifest.xml`
  (`RECORD_AUDIO`, `CAMERA`, `INTERNET`, `MODIFY_AUDIO_SETTINGS`, …)
- `ios/Runner/Info.plist`
  (`NSMicrophoneUsageDescription`, `NSCameraUsageDescription`)

Runtime flow (`permission_handler`): request mic (+ camera for video)
before `CallProvider.startCall`; denied → SnackBar; permanently denied →
dialog with **Open Settings**.

## 4. Architecture

```
lib/
  core/constants/app_constants.dart  (Zego keys, routes)
  core/theme/app_theme.dart          (Material3 light/dark)
  core/utils/permission_helper.dart  (mic/camera + settings dialog)
  core/utils/time_utils.dart         (MM:SS, intl history time)
  models/user_model.dart, call_model.dart (+ CallSession state machine)
  services/auth_service.dart (auth+presence+FCM)
           user_service.dart (users stream)
           calling_service.dart (Zego singleton: init/send/accept/reject/cancel)
           history_service.dart (history for BOTH users)
  providers/auth_provider.dart (currentUser/isLoading/error + checkAuth/signIn/signUp/signOut/updatePresence)
            users_provider.dart (users/searchQuery/isLoading + fetchUsers/setSearch, Firestore Stream)
            call_provider.dart (currentCall/callStatus/isMuted/isCameraOff/isSpeakerOn/duration + startCall/accept/reject/end/toggles)
  screens/splash, auth, home, contacts, profile, call (audio/video/incoming), history
  widgets/user_tile, call_button, common_button
  main.dart (MultiProvider + routes)
```

## 5. Interview explanation

**How Zego works here:**
1. `AuthProvider` login → `CallingService.initZego(uid, name)` calls
   `ZegoUIKitPrebuiltCallInvitationService().init(appID, appSign, userID,
   userName, plugins: [ZegoUIKitSignalingPlugin()], requireConfig,
   invitationEvents)`. `requireConfig` returns
   `oneOnOneVideoCall()` vs `oneOnOneVoiceCall()` based on
   `ZegoCallInvitationType`.
2. Caller: `sendCallInvitation(invitees:[ZegoCallUser(id,name)],
   isVideoCall, callID, customData: callerPhoto)` — signaling goes over
   ZIM; media later goes over Zego RTC rooms keyed by the same `callID`.
3. Callee: `onIncomingCallReceived(callID, caller, callType, …)` builds a
   `CallSession` → `CallProvider` sets `ringing` → `HomeScreen` pushes
   `/incoming`. Accept calls SDK `accept()` + navigates to
   `ZegoUIKitPrebuiltCall(appID, appSign, userID, userName, callID,
   config)`; Reject calls SDK `reject()` → caller gets
   `onOutgoingCallDeclined`. Timeout/busy map to `failed/missed/busy`.
4. In-room: `ZegoUIKitPrebuiltCallEvents(onCallEnd, user.onEnter)` —
   first remote join → `markConnected()` starts the MM:SS timer;
   hangup → `CallProvider.end()` → `HistoryService.saveCallForBoth`
   writes mirrored docs under both users' `call_history`.
5. Mute/camera/speaker buttons are Zego's prebuilt toolbar driving the
   same engine `CallProvider` mirrors via `ZegoUIKit().turnMicrophoneOn /
   turnCameraOn / setAudioOutputToSpeaker`, so custom UI and SDK never
   diverge.

**How Provider/ChangeNotifier communicates with UI:**
- `main.dart` exposes exactly three `ChangeNotifierProvider`s in a
  `MultiProvider` (no Riverpod/Bloc/GetX).
- Each provider holds private state + public getters and mutates only via
  methods that end with `notifyListeners()` (e.g. `AuthProvider.signIn`,
  `UsersProvider.setSearch`, `CallProvider.toggleMute`).
- Screens never hold business logic: they `context.watch`/`Consumer` for
  rebuilds (`isLoading` → spinner, `error` → SnackBar, `users` →
  ListView, `callStatus/duration` → header/timer) and `context.read` for
  one-shot actions (login, startCall, accept). `UsersProvider` subscribes
  to a Firestore `Stream` once (`fetchUsers`) and re-emits snapshots;
  `CallProvider` subscribes to Zego invitation callbacks once
  (`bindLocalUser`) and re-emits call-state transitions. State flows
  one way: SDK/Firestore → service → provider → `notifyListeners` → UI.

## 6. Limitations

- Foreground/online calls only; killed-app/offline push needs Zego
  `resourceID` + FCM/APNs cert (not configured).
- 1-to-1 only; no group calls, no chat, no profile-photo upload
  (`photoUrl` reserved).
- Presence is a simple `isOnline` boolean (no heartbeat/typing).
- History capped at 100/docs per user, no pagination beyond that.
- `customData` carries only caller photo URL (no full signaling payload).
#   C o n n e c t - C a l l  
 