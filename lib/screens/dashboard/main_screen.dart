import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/expense_tile.dart';
import 'home_tab.dart';
import 'calendar_tab.dart';
import 'stats_tab.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override State<MainScreen> createState() => _MS();
}

class _MS extends State<MainScreen> with SingleTickerProviderStateMixin {
  late AppState _as;
  int _idx = 0;
  bool _listening = false;
  late final AnimationController _fabAc;

  static const _tabs = [HomeTab(), CalendarTab(), StatsTab(), ProfileScreen()];

  void _r() { if (mounted) setState(() {}); }

  @override
  void initState() {
    super.initState();
    _fabAc = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fabAc.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listening) {
      _listening = true;
      _as = AppState.of(context);
      _as.notifs.addListener(_r);
    }
  }

  @override
  void dispose() {
    _fabAc.dispose();
    _as.notifs.removeListener(_r);
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: ctx.cBg,
    body: AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
      child: KeyedSubtree(key: ValueKey(_idx), child: _tabs[_idx]),
    ),
    bottomNavigationBar: _nav(ctx),
    floatingActionButton: (_idx == 0 || _idx == 1) ? _fab(ctx) : null,
    floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
  );

  Widget _fab(BuildContext ctx) => ScaleTransition(
    scale: CurvedAnimation(parent: _fabAc, curve: Curves.elasticOut),
    child: FloatingActionButton(
      onPressed: () => showAddSheet(ctx),
      backgroundColor: kP, elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 26)));

  Widget _nav(BuildContext ctx) {
    final unread = AppState.of(ctx).notifs.unread;
    final dark   = AppState.of(ctx).dark;
    return Container(
      decoration: BoxDecoration(
        color: ctx.cCard,
        border: Border(top: BorderSide(color: ctx.cBord)),
        boxShadow: ctx.isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded,           Icons.home_outlined,           'Home',     0),
              _navItem(1, Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Calendar', 0),
              _navItem(2, Icons.bar_chart_rounded,      Icons.bar_chart_outlined,      'Stats',    0),
              _navItem(3, Icons.person_rounded,         Icons.person_outline_rounded,  'Profile',  unread),
              // ── Theme toggle pill ──────────────────────────────────────────
              ValueListenableBuilder<bool>(
                valueListenable: dark,
                builder: (_, dk, __) => GestureDetector(
                  onTap: () => dark.value = !dk,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: dk ? kCard2 : kCard2L,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: dk ? kBord : kBordL),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (c, a) => RotationTransition(turns: a, child: FadeTransition(opacity: a, child: c)),
                        child: Icon(
                          dk ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          key: ValueKey(dk),
                          color: dk ? const Color(0xFFFBBF24) : kP,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        dk ? 'Light' : 'Dark',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: dk ? const Color(0xFFFBBF24) : kP,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData active, IconData inactive, String label, int badge) {
    final sel = _idx == idx;
    return GestureDetector(
      onTap: () {
        if (_idx != idx) {
          setState(() => _idx = idx);
          if (idx == 0 || idx == 1) { _fabAc.reset(); _fabAc.forward(); }
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? kP.withOpacity(.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(children: [
            Icon(sel ? active : inactive, size: 22,
                color: sel ? kP : (context.isDark ? kTxt3 : kTxt3L)),
            if (badge > 0) Positioned(right: 0, top: 0,
              child: Container(width: 7, height: 7,
                decoration: const BoxDecoration(color: kP, shape: BoxShape.circle))),
          ]),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
              fontSize: 10,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              color: sel ? kP : (context.isDark ? kTxt3 : kTxt3L))),
        ]),
      ),
    );
  }
}
