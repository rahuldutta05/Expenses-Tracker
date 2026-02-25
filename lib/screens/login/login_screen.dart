import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';
import '../dashboard/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LS();
}

class _LS extends State<LoginScreen> with TickerProviderStateMixin {
  final _nc = TextEditingController();
  final _ec = TextEditingController();
  bool _loading = false;
  late final AnimationController _ac;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ac    = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade  = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, .05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    _ac.forward();
  }

  @override
  void dispose() { _ac.dispose(); _nc.dispose(); _ec.dispose(); super.dispose(); }

  Future<void> _go() async {
    if (_nc.text.trim().isEmpty || _ec.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Please fill in all fields'),
          backgroundColor: context.cCard, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      return;
    }
    setState(() => _loading = true);
    final s = AppState.of(context);
    await s.users.login(_nc.text.trim(), _ec.text.trim());
    await s.exp.load(); await s.notifs.load();
    if (mounted) Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()));
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: ctx.cBg,
    body: SafeArea(child: FadeTransition(opacity: _fade, child: SlideTransition(position: _slide,
      child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _logo(ctx), const SizedBox(height: 52),
          _form(ctx), const SizedBox(height: 28),
          _quickSwitch(ctx),
        ]))))));

  Widget _logo(BuildContext ctx) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    // App icon
    Container(width: 60, height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [kD, kP], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: kP.withOpacity(.4), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 30)),
    const SizedBox(height: 28),
    Text('ExpenseFlow', style: TextStyle(
      color: ctx.cTxt, fontSize: 36,
      fontWeight: FontWeight.w900, letterSpacing: -1.5,
    )),
    const SizedBox(height: 6),
    Text('Smart money tracking.', style: TextStyle(color: ctx.cTxt2, fontSize: 15)),
    const SizedBox(height: 22),
    Wrap(spacing: 8, runSpacing: 8, children: [
      _tag(ctx, Icons.people_rounded,        'Multi-user'),
      _tag(ctx, Icons.notifications_rounded, 'Smart alerts'),
      _tag(ctx, Icons.analytics_rounded,     'Analytics'),
      _tag(ctx, Icons.savings_rounded,       'Budget'),
    ]),
  ]);

  Widget _tag(BuildContext ctx, IconData icon, String l) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: ctx.cCard2, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ctx.cBord)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: kP, size: 11), const SizedBox(width: 5),
      Text(l, style: TextStyle(color: ctx.cTxt2, fontSize: 11, fontWeight: FontWeight.w600)),
    ]));

  Widget _form(BuildContext ctx) => Container(
    padding: const EdgeInsets.all(26),
    decoration: cardDeco(ctx, radius: 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Get Started', style: TextStyle(color: ctx.cTxt, fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 3),
      Text('Login or create account instantly', style: TextStyle(color: ctx.cTxt3, fontSize: 12)),
      const SizedBox(height: 26),
      _inp(ctx, _nc, 'Full Name', Icons.person_rounded),
      const SizedBox(height: 12),
      _inp(ctx, _ec, 'Email Address', Icons.email_rounded, type: TextInputType.emailAddress),
      const SizedBox(height: 26),
      SizedBox(width: double.infinity, height: 54,
        child: ElevatedButton(onPressed: _loading ? null : _go,
          style: ElevatedButton.styleFrom(
            backgroundColor: kP, foregroundColor: Colors.white,
            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            shadowColor: kP.withOpacity(.4),
          ),
          child: _loading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : const Text('Continue →', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)))),
    ]));

  Widget _inp(BuildContext ctx, TextEditingController c, String h, IconData icon,
      {TextInputType type = TextInputType.text}) => TextField(
    controller: c, keyboardType: type,
    style: TextStyle(color: ctx.cTxt, fontSize: 14),
    decoration: InputDecoration(hintText: h, hintStyle: TextStyle(color: ctx.cTxt3),
      prefixIcon: Icon(icon, color: ctx.cTxt3, size: 18),
      filled: true, fillColor: ctx.cCard2,
      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: ctx.cBord)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: ctx.cBord)),
      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(13)), borderSide: BorderSide(color: kP, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(vertical: 14)));

  Widget _quickSwitch(BuildContext ctx) {
    final users = AppState.of(ctx).users.all;
    if (users.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('QUICK SWITCH', style: TextStyle(color: ctx.cTxt3, fontSize: 10,
          fontWeight: FontWeight.w700, letterSpacing: 1.5)),
      const SizedBox(height: 14),
      SizedBox(height: 84, child: ListView.separated(scrollDirection: Axis.horizontal,
        itemCount: users.length, separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final u = users[i];
          return GestureDetector(
            onTap: () async {
              final s = AppState.of(context);
              await s.users.switchTo(u); await s.exp.load(); await s.notifs.load();
              if (mounted) Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainScreen()));
            },
            child: Container(width: 76,
              decoration: cardDeco(ctx, radius: 18),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                CircleAvatar(radius: 22, backgroundColor: kP.withOpacity(.12),
                  child: Text(u.avatar, style: const TextStyle(color: kP,
                      fontWeight: FontWeight.w800, fontSize: 13))),
                const SizedBox(height: 7),
                Text(u.name.split(' ').first, style: TextStyle(fontSize: 10,
                    fontWeight: FontWeight.w600, color: ctx.cTxt2), overflow: TextOverflow.ellipsis),
              ])));
        })),
    ]);
  }
}
