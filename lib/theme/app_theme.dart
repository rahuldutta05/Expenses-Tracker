import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS
// ══════════════════════════════════════════════════════════════════════════════
const kP     = Color(0xFFFF6B35);
const kD     = Color(0xFFE85520);
const kL     = Color(0xFFFF9A6C);
const kGreen = Color(0xFF22C55E);
const kRed   = Color(0xFFEF4444);

// dark
const kBg    = Color(0xFF0A0A0F);
const kSurf  = Color(0xFF111118);
const kCard  = Color(0xFF1A1A24);
const kCard2 = Color(0xFF22222E);
const kBord  = Color(0xFF2C2C3A);
const kTxt   = Color(0xFFF0F0F8);
const kTxt2  = Color(0xFF8A8AA0);
const kTxt3  = Color(0xFF4A4A62);

// light
const kBgL    = Color(0xFFF5F4FF);
const kSurfL  = Color(0xFFF8F7FF);
const kCardL  = Color(0xFFFFFFFF);
const kCard2L = Color(0xFFF0EFF9);
const kBordL  = Color(0xFFE2E1F0);
const kTxtL   = Color(0xFF1A1A2E);
const kTxt2L  = Color(0xFF6B6B8A);
const kTxt3L  = Color(0xFFAAAAAC);

extension CtxTheme on BuildContext {
  bool   get isDark  => Theme.of(this).brightness == Brightness.dark;
  Color  get cBg     => isDark ? kSurf  : kSurfL;
  Color  get cCard   => isDark ? kCard  : kCardL;
  Color  get cCard2  => isDark ? kCard2 : kCard2L;
  Color  get cBord   => isDark ? kBord  : kBordL;
  Color  get cTxt    => isDark ? kTxt   : kTxtL;
  Color  get cTxt2   => isDark ? kTxt2  : kTxt2L;
  Color  get cTxt3   => isDark ? kTxt3  : kTxt3L;
}

BoxDecoration cardDeco(BuildContext ctx, {double radius = 18, Color? border}) =>
    BoxDecoration(
      color: ctx.cCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border ?? ctx.cBord),
      boxShadow: ctx.isDark
          ? []
          : [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 14, offset: const Offset(0, 4))],
    );

class AppTheme {
  static ThemeData dark() => _make(Brightness.dark,
    scaffold: kSurf, card: kCard,
    cs: const ColorScheme.dark(
      primary: kP, secondary: kL, surface: kCard, background: kSurf,
      onPrimary: Colors.white, onSurface: kTxt, onBackground: kTxt, error: kRed,
    ),
    appBarBg: kCard, appBarFg: kTxt,
    navBg: kCard, navSel: kP, navUn: kTxt3,
    fill: kCard2, border: kBord, hint: kTxt3,
    t1: kTxt, t2: kTxt2,
    dialogBg: kCard,
  );

  static ThemeData light() => _make(Brightness.light,
    scaffold: kSurfL, card: kCardL,
    cs: ColorScheme.light(
      primary: kP, secondary: kL, surface: kCardL, background: kSurfL,
      onPrimary: Colors.white, onSurface: kTxtL, onBackground: kTxtL, error: kRed,
    ),
    appBarBg: kCardL, appBarFg: kTxtL,
    navBg: kCardL, navSel: kP, navUn: kTxt3L,
    fill: kCard2L, border: kBordL, hint: kTxt3L,
    t1: kTxtL, t2: kTxt2L,
    dialogBg: kCardL,
  );

  static ThemeData _make(Brightness b, {
    required Color scaffold, required Color card, required ColorScheme cs,
    required Color appBarBg, required Color appBarFg,
    required Color navBg, required Color navSel, required Color navUn,
    required Color fill, required Color border, required Color hint,
    required Color t1, required Color t2, required Color dialogBg,
  }) => ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    brightness: b,
    colorScheme: cs,
    scaffoldBackgroundColor: scaffold,
    cardColor: card,
    dividerColor: border,
    dialogBackgroundColor: dialogBg,
    appBarTheme: AppBarTheme(
      backgroundColor: appBarBg, foregroundColor: appBarFg,
      elevation: 0, surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: navBg, selectedItemColor: navSel, unselectedItemColor: navUn,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: fill,
      hintStyle: TextStyle(color: hint), labelStyle: TextStyle(color: hint),
      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kP, width: 1.5)),
    ),
    textTheme: TextTheme(
      bodyLarge:  TextStyle(color: t1, fontFamily: 'Poppins'),
      bodyMedium: TextStyle(color: t1, fontFamily: 'Poppins'),
      bodySmall:  TextStyle(color: t2, fontFamily: 'Poppins'),
    ),
    iconTheme: IconThemeData(color: t2),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected) ? kP : Colors.grey.shade500),
      trackColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected) ? kP.withOpacity(.3) : Colors.grey.withOpacity(.25)),
    ),
  );
}

// ── Google Fonts helper — call once in main to apply Poppins globally ─────────
// Import google_fonts in main.dart and call:
//   GoogleFonts.poppinsTextTheme()
// inside your MaterialApp theme builders.
