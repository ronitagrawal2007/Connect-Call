import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/call_provider.dart';
import '../../providers/users_provider.dart';
import '../../widgets/brand_mark.dart';

/// Single-colour background (white light / black dark), centered lockup.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final started = DateTime.now();
    final auth = context.read<AuthProvider>();
    await auth.checkAuth();
    if (!mounted) return;
    if (auth.isLoggedIn && auth.currentUser != null) {
      context.read<UsersProvider>().setSelfUid(auth.currentUser!.uid);
      context.read<UsersProvider>().fetchUsers();
      context.read<CallProvider>().bindLocalUser(auth.currentUser!);
    }
    final elapsed = DateTime.now().difference(started).inMilliseconds;
    if (elapsed < 1500) {
      await Future.delayed(Duration(milliseconds: 1500 - elapsed));
    }
    if (!mounted) return;
    if (auth.isLoggedIn) {
      Navigator.pushReplacementNamed(context, AppConstants.routeHome);
    } else {
      Navigator.pushReplacementNamed(context, AppConstants.routeLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spinnerColor =
        isDark ? Colors.white.withValues(alpha: 0.9) : AppTheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMark(iconSize: 110, dark: isDark),
            const SizedBox(height: 48),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: spinnerColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
