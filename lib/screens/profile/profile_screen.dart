import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../../utils/cats.dart';
import '../../theme/app_theme.dart';
import '../login/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _PS();
}

class _PS extends State<ProfileScreen> {
  @override
  Widget build(BuildContext ctx) {
    final s = AppState.of(ctx); final u = s.users.current!; final exp = s.exp;
    return Scaffold(
      backgroundColor: ctx.cBg,
      appBar: AppBar(
        backgroundColor: ctx.cCard,
        surfaceTintColor: Colors.transparent,
        title: Text('Profile', style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w800, fontSize: 20)),
        actions: [
          IconButton(icon: Icon(Icons.settings_outlined, color: ctx.cTxt2),
            onPressed: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const _SettingsScreen()))),
        ],
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16),
        child: Column(children: [
          _hero(ctx, u, exp), const SizedBox(height: 16),
          _statsRow(ctx, exp),  const SizedBox(height: 16),
          _section(ctx, 'Preferences', [
            _tile(ctx, Icons.savings_rounded, 'Monthly Budget', '${exp.cur}${exp.budget.toInt()}',
                kGreen, () => _budgetDlg(ctx)),
            _tile(ctx, Icons.currency_exchange_rounded, 'Currency', exp.cur,
                Colors.blue.shade300, () => _curDlg(ctx)),
            _switchTile(ctx, s),
          ]),
          const SizedBox(height: 12),
          if (s.users.all.length > 1) ...[
            _section(ctx, 'Accounts', [
              ...s.users.all.map((u2) {
                final active = u2.id == u.id;
                return ListTile(
                  leading: CircleAvatar(radius: 18,
                    backgroundColor: active ? kP.withOpacity(.15) : ctx.cCard2,
                    child: Text(u2.avatar, style: TextStyle(
                        color: active ? kP : ctx.cTxt2, fontWeight: FontWeight.w800, fontSize: 11))),
                  title: Text(u2.name, style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(u2.email, style: TextStyle(color: ctx.cTxt3, fontSize: 11)),
                  trailing: active
                      ? Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: kP.withOpacity(.12), borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: kP.withOpacity(.3))),
                          child: const Text('Active', style: TextStyle(color: kP, fontSize: 10, fontWeight: FontWeight.w700)))
                      : TextButton(onPressed: () async {
                          final st = AppState.of(context);
                          await st.users.switchTo(u2); await st.exp.load(); await st.notifs.load();
                          if (mounted) setState((){});
                        }, child: const Text('Switch', style: TextStyle(color: kP))));
              }),
            ]),
            const SizedBox(height: 12),
          ],
          _section(ctx, 'Account', [
            _tile(ctx, Icons.logout_rounded, 'Logout', 'Sign out of your account',
                Colors.orange.shade400, () => _logout(ctx)),
            _tile(ctx, Icons.person_remove_rounded, 'Delete Account', 'Permanently remove data',
                kRed, () => _delDlg(ctx)),
          ]),
          const SizedBox(height: 60),
        ])),
    );
  }

  Widget _hero(BuildContext ctx, u, exp) => Container(
    padding: const EdgeInsets.all(20),
    decoration: cardDeco(ctx, radius: 22),
    child: Row(children: [
      Stack(children: [
        Container(width: 72, height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [kP.withOpacity(.3), kD.withOpacity(.2)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            shape: BoxShape.circle,
            border: Border.all(color: kP.withOpacity(.4), width: 2),
          ),
          child: Center(child: Text(u.avatar,
              style: const TextStyle(color: kP, fontWeight: FontWeight.w900, fontSize: 28)))),
        Positioned(right: 0, bottom: 0,
          child: GestureDetector(onTap: () => _editName(ctx),
            child: Container(width: 26, height: 26,
              decoration: BoxDecoration(color: kP, shape: BoxShape.circle, border: Border.all(color: ctx.cCard, width: 2)),
              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 12)))),
      ]),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(u.name, style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 3),
        Text(u.email, style: TextStyle(color: ctx.cTxt2, fontSize: 12)),
        const SizedBox(height: 12),
        Row(children: [
          _badge(ctx, '${exp.cur}${exp.budget.toInt()}', 'Budget'),
          const SizedBox(width: 8),
          _badge(ctx, exp.cur, 'Currency'),
        ]),
      ])),
    ]));

  Widget _badge(BuildContext ctx, String v, String l) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: ctx.cCard2, borderRadius: BorderRadius.circular(10), border: Border.all(color: ctx.cBord)),
    child: Text('$v  $l', style: TextStyle(color: ctx.cTxt2, fontSize: 10, fontWeight: FontWeight.w600)));

  Widget _statsRow(BuildContext ctx, exp) {
    final total = exp.totalMonth;
    final cnt   = exp.expenses.where((e) => e.date.month == DateTime.now().month).length;
    final pct   = ((total / exp.budget) * 100).clamp(0, 999).toInt();
    return Row(children: [
      _statBox(ctx, '${exp.cur}${total.toInt()}', 'Spent',        kP),
      const SizedBox(width: 10),
      _statBox(ctx, '$cnt',  'Transactions',    kGreen),
      const SizedBox(width: 10),
      _statBox(ctx, '$pct%', 'Budget Used',     total > exp.budget ? kRed : Colors.blue.shade300),
    ]);
  }

  Widget _statBox(BuildContext ctx, String v, String l, Color c) => Expanded(
    child: Container(padding: const EdgeInsets.all(14),
      decoration: cardDeco(ctx, radius: 14),
      child: Column(children: [
        Text(v, style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 16), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(l, style: TextStyle(color: ctx.cTxt3, fontSize: 10), textAlign: TextAlign.center),
      ])));

  Widget _section(BuildContext ctx, String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title.toUpperCase(),
            style: TextStyle(color: ctx.cTxt3, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5))),
      Container(decoration: cardDeco(ctx, radius: 16), child: Column(children: children)),
      const SizedBox(height: 4),
    ]);

  Widget _tile(BuildContext ctx, IconData icon, String t, String s, Color c, VoidCallback fn) =>
    ListTile(onTap: fn, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: c.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: c, size: 18)),
      title: Text(t, style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(s, style: TextStyle(color: ctx.cTxt3, fontSize: 11)),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: ctx.cTxt3));

  Widget _switchTile(BuildContext ctx, s) => ValueListenableBuilder<bool>(
    valueListenable: s.dark,
    builder: (_, dk, __) => SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      secondary: Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: dk ? [const Color(0xFF1A1A40), const Color(0xFF3730A3)]
                       : [const Color(0xFFFEF3C7), const Color(0xFFFBBF24)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(dk ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: dk ? const Color(0xFF818CF8) : const Color(0xFFFBBF24), size: 18)),
      title: Text('${dk ? 'Dark' : 'Light'} Mode',
          style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(dk ? 'Tap to switch to light' : 'Tap to switch to dark',
          style: TextStyle(color: ctx.cTxt3, fontSize: 11)),
      value: dk, activeColor: kP, onChanged: (v) => s.dark.value = v));

  void _editName(BuildContext ctx) {
    final c = TextEditingController(text: AppState.of(ctx).users.current!.name);
    _dlg(ctx, 'Edit Name', TextField(controller: c,
        style: TextStyle(color: ctx.cTxt),
        decoration: InputDecoration(labelText: 'Full Name',
            labelStyle: TextStyle(color: ctx.cTxt2),
            filled: true, fillColor: ctx.cCard2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: ctx.cBord)),
            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: kP)))),
      () async { await AppState.of(ctx).users.update(name: c.text.trim()); setState((){}); });
  }

  void _budgetDlg(BuildContext ctx) {
    final c = TextEditingController(text: AppState.of(ctx).exp.budget.toInt().toString());
    _dlg(ctx, 'Monthly Budget', TextField(controller: c, keyboardType: TextInputType.number,
        style: TextStyle(color: ctx.cTxt),
        decoration: InputDecoration(prefixText: AppState.of(ctx).exp.cur,
            prefixStyle: const TextStyle(color: kP), labelText: 'Amount',
            labelStyle: TextStyle(color: ctx.cTxt2),
            filled: true, fillColor: ctx.cCard2,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: ctx.cBord)),
            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: kP)))),
      () async {
        final v = double.tryParse(c.text) ?? 5000;
        final s = AppState.of(ctx); s.exp.budget = v; await s.users.update(budget: v); setState((){});
      });
  }

  void _curDlg(BuildContext ctx) => showDialog(context: ctx,
    builder: (dlg) => AlertDialog(
      backgroundColor: ctx.cCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: ctx.cBord)),
      title: Text('Currency', style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w800)),
      content: Column(mainAxisSize: MainAxisSize.min, children: kCurs.map((cur) {
        final sel = AppState.of(ctx).exp.cur == cur;
        return ListTile(onTap: () async {
          final s = AppState.of(ctx); s.exp.cur = cur; await s.users.update(currency: cur);
          if (mounted) { Navigator.pop(dlg); setState((){}); }},
          leading: Text(cur, style: const TextStyle(fontSize: 20, color: kP)),
          title: Text(curName(cur), style: TextStyle(color: ctx.cTxt, fontSize: 13)),
          trailing: sel ? const Icon(Icons.check_rounded, color: kP) : null);
      }).toList())));

  void _dlg(BuildContext ctx, String title, Widget field, VoidCallback fn) =>
    showDialog(context: ctx, builder: (dlg) => AlertDialog(
      backgroundColor: ctx.cCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: ctx.cBord)),
      title: Text(title, style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w800)),
      content: field,
      actions: [
        TextButton(onPressed: () => Navigator.pop(dlg),
          child: Text('Cancel', style: TextStyle(color: ctx.cTxt2))),
        ElevatedButton(onPressed: () { fn(); Navigator.pop(dlg); },
          style: ElevatedButton.styleFrom(backgroundColor: kP, foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Save')),
      ]));

  void _logout(BuildContext ctx) async {
    await AppState.of(ctx).users.logout();
    if (mounted) Navigator.of(ctx).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  void _delDlg(BuildContext ctx) => showDialog(context: ctx,
    builder: (dlg) => AlertDialog(
      backgroundColor: ctx.cCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: ctx.cBord)),
      title: Text('Delete Account', style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w800)),
      content: Text('Permanently deletes your account and all data.', style: TextStyle(color: ctx.cTxt2)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dlg),
          child: Text('Cancel', style: TextStyle(color: ctx.cTxt2))),
        ElevatedButton(onPressed: () async {
          await AppState.of(ctx).users.deleteCurrent();
          if (mounted) Navigator.of(ctx).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);},
          style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Delete Forever')),
      ]));
}

// ── Inline Settings Screen ─────────────────────────────────────────────────
class _SettingsScreen extends StatefulWidget {
  const _SettingsScreen();
  @override State<_SettingsScreen> createState() => _SS();
}
class _SS extends State<_SettingsScreen> {
  @override Widget build(BuildContext ctx) {
    final s = AppState.of(ctx); final exp = s.exp;
    return Scaffold(backgroundColor: ctx.cBg,
      appBar: AppBar(backgroundColor: ctx.cCard, surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: Icon(Icons.arrow_back_rounded, color: ctx.cTxt2),
          onPressed: () => Navigator.pop(ctx)),
        title: Text('Settings', style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w800, fontSize: 20))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sec(ctx, 'PREFERENCES'), const SizedBox(height: 8),
          _card(ctx, [
            _row(ctx, Icons.savings_rounded, 'Budget', '${exp.cur}${exp.budget.toInt()}', kGreen, () {}),
            _div(ctx), _row(ctx, Icons.currency_exchange_rounded, 'Currency', exp.cur, Colors.blue.shade300, () {}),
            _div(ctx),
            ValueListenableBuilder<bool>(valueListenable: s.dark, builder: (_, dk, __) => SwitchListTile(
              secondary: Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: dk ? [const Color(0xFF1A1A40), const Color(0xFF3730A3)]
                               : [const Color(0xFFFEF3C7), const Color(0xFFFBBF24)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(dk ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: dk ? const Color(0xFF818CF8) : const Color(0xFFFBBF24), size: 18)),
              title: Text('${dk ? 'Dark' : 'Light'} Mode', style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w600, fontSize: 14)),
              value: dk, activeColor: kP, onChanged: (v) => s.dark.value = v)),
          ]),
          const SizedBox(height: 20), _sec(ctx, 'DATA'), const SizedBox(height: 8),
          _card(ctx, [
            _row(ctx, Icons.download_rounded, 'Export CSV', 'Save all expenses', Colors.teal, () async {
              final path = await exp.exportCSV();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Exported: $path'), backgroundColor: ctx.cCard,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
            }),
            _div(ctx),
            _row(ctx, Icons.delete_forever_rounded, 'Delete All Expenses', 'Clear all records', kRed, () =>
              showDialog(context: ctx, builder: (dlg) => AlertDialog(
                backgroundColor: ctx.cCard,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: ctx.cBord)),
                title: Text('Delete All', style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w800)),
                content: Text('Permanently deletes all expense records.', style: TextStyle(color: ctx.cTxt2)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(dlg), child: Text('Cancel', style: TextStyle(color: ctx.cTxt2))),
                  ElevatedButton(onPressed: () async { await exp.clear(); if (mounted) Navigator.pop(dlg); },
                    style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white, elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Delete All')),
                ]))),
          ]),
          const SizedBox(height: 20), _sec(ctx, 'ABOUT'), const SizedBox(height: 8),
          _card(ctx, [
            _row(ctx, Icons.info_outline_rounded, 'Version', '1.0.0 · ExpenseFlow', Colors.grey, () {}),
            _div(ctx),
            _row(ctx, Icons.code_rounded, 'Built with', 'Flutter · Dart', Colors.blue.shade300, () {}),
          ]),
          const SizedBox(height: 40),
        ])));
  }
  Widget _sec(BuildContext ctx, String t) => Text(t,
      style: TextStyle(color: ctx.cTxt3, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5));
  Widget _card(BuildContext ctx, List<Widget> ch) => Container(
    decoration: cardDeco(ctx, radius: 16), child: Column(children: ch));
  Widget _row(BuildContext ctx, IconData icon, String t, String s, Color c, VoidCallback fn) =>
    ListTile(onTap: fn, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: c.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: c, size: 18)),
      title: Text(t, style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(s, style: TextStyle(color: ctx.cTxt3, fontSize: 11)),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: ctx.cTxt3));
  Widget _div(BuildContext ctx) => Divider(height: 1, color: ctx.cBord, indent: 56);
}
