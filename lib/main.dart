import 'package:flutter/material.dart';
import 'app_state.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.load();
  runApp(ExpenseTrackerApp(state: state));
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: appName,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        scaffoldMessengerKey: messengerKey,
        // On wide screens, show the app as a centred phone-width column.
        builder: (context, child) => ColoredBox(
          color: const Color(0xFFE9ECEA),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: ClipRect(child: child),
            ),
          ),
        ),
        home: const _Gate(),
      ),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate();
  @override
  Widget build(BuildContext context) =>
      AppScope.of(context).loggedIn ? const HomeShell() : const LoginScreen();
}
