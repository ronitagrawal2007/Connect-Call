// ignore_for_file: constant_identifier_names
// Fixed Zego credentials — DO NOT CHANGE per spec.
const int ZEGO_APP_ID = 1664373490;
const String ZEGO_APP_SIGN =
    "120eb6a56f8babab35b8347a1d27c5bf4397bdb6b00f1cc7645eb1207389ead5";

class AppConstants {
  static const String appName = 'Connect Call';
  static const String tagline = 'Connect with anyone, anywhere.';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String historySubcollection = 'call_history';

  // Zego
  static const int callTimeoutSeconds = 60;

  // Routes
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeHome = '/home';
  static const String routeAudioCall = '/audio-call';
  static const String routeVideoCall = '/video-call';
  static const String routeIncoming = '/incoming';
}
