import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/call_provider.dart';
import '../contacts/contacts_screen.dart';
import '../history/call_history_screen.dart';
import '../profile/profile_screen.dart';
import 'home_tab.dart';

/// Nav shell — every primary tab shares the same incoming-call listener.
/// Shell and bar use the theme scaffold color: white in light, black in dark.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  String? _lastIncomingId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Consumer<CallProvider>(
      builder: (context, call, _) {
        final incoming = call.currentCall;
        if (incoming != null &&
            !incoming.isOutgoing &&
            call.callStatus == 'ringing' &&
            _lastIncomingId != incoming.callId) {
          _lastIncomingId = incoming.callId;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.pushNamed(context, AppConstants.routeIncoming);
          });
        }
        if (call.callStatus == 'idle') _lastIncomingId = null;

        return Scaffold(
          body: IndexedStack(
            index: _index,
            children: const [
              HomeTab(),
              ContactsScreen(),
              CallHistoryScreen(),
              ProfileScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: scheme.primary),
                label: 'Home',
              ),
              NavigationDestination(
                icon: const Icon(Icons.contacts_outlined),
                selectedIcon: Icon(Icons.contacts, color: scheme.primary),
                label: 'Contacts',
              ),
              NavigationDestination(
                icon: const Icon(Icons.call_outlined),
                selectedIcon: Icon(Icons.call, color: scheme.primary),
                label: 'Calls',
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: scheme.primary),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}
