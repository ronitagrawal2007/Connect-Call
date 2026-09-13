import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/call_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/users_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/call/audio_call_screen.dart';
import 'screens/call/video_call_screen.dart';
import 'screens/call/incoming_call_screen.dart';

/// Background FCM handler (must be top-level).
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  // No-op: Zego offline push uses its own resourceID flow.
  // Keeping handler registered prevents crashes when pushes arrive.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);
  try {
    await FirebaseMessaging.instance.requestPermission();
  } catch (_) {}
  // Load saved theme (light/white vs dark/black) before first frame
  // so there is no flash and the choice persists across restarts.
  final themeProvider = await ThemeProvider.load();
  await themeProvider.migrateLegacyIfNeeded();
  runApp(ConnectCallApp(themeProvider: themeProvider));
}

class ConnectCallApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  const ConnectCallApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UsersProvider()),
        ChangeNotifierProvider(create: (_) => CallProvider()),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            initialRoute: AppConstants.routeSplash,
            routes: {
              AppConstants.routeSplash: (_) => const SplashScreen(),
              AppConstants.routeLogin: (_) => const LoginScreen(),
              AppConstants.routeRegister: (_) => const RegisterScreen(),
              AppConstants.routeHome: (_) => const HomeScreen(),
              AppConstants.routeAudioCall: (_) => const AudioCallScreen(),
              AppConstants.routeVideoCall: (_) => const VideoCallScreen(),
              AppConstants.routeIncoming: (_) => const IncomingCallScreen(),
            },
          );
        },
      ),
    );
  }
}
