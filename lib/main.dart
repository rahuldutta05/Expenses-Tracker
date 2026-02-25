import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/user_store.dart';
import 'services/expense_store.dart';
import 'services/notif_store.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/login/login_screen.dart';
import 'screens/dashboard/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const EFApp());
}

class EFApp extends StatefulWidget {
  const EFApp({super.key});
  @override State<EFApp> createState() => _EFAppState();
}

class _EFAppState extends State<EFApp> {
  final _users = UserStore();
  final _dark  = ValueNotifier<bool>(true);
  late NotifStore   _notifs;
  late ExpenseStore _exp;
  bool _ready = false;

  @override void initState() { super.initState(); _boot(); }

  Future<void> _boot() async {
    await _users.init();
    final uid = _users.current?.id ?? '__guest__';
    _notifs = NotifStore(uid);
    _exp    = ExpenseStore(uid, _notifs);
    if (_users.loggedIn) {
      await _exp.load();
      await _notifs.load();
    }
    setState(() => _ready = true);
  }

  @override void dispose() { _dark.dispose(); super.dispose(); }

  ThemeData _applyPoppins(ThemeData base) {
    final poppins = GoogleFonts.poppinsTextTheme(base.textTheme);
    return base.copyWith(
      textTheme: poppins,
      primaryTextTheme: GoogleFonts.poppinsTextTheme(base.primaryTextTheme),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    if (!_ready) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(kP)))),
      );
    }
    return AppState(
      users:  _users,
      exp:    _exp,
      notifs: _notifs,
      dark:   _dark,
      child: ValueListenableBuilder<bool>(
        valueListenable: _dark,
        builder: (_, dark, __) {
          // Update status bar icon brightness based on theme
          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          ));
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'ExpenseFlow',
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            theme:     _applyPoppins(AppTheme.light()),
            darkTheme: _applyPoppins(AppTheme.dark()),
            home: _users.loggedIn ? const MainScreen() : const LoginScreen(),
          );
        },
      ),
    );
  }
}
