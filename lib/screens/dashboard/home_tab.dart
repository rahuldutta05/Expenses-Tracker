import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/app_state.dart';
import '../../utils/cats.dart';
import '../../utils/analytics.dart';
import '../../widgets/expense_tile.dart';
import '../../theme/app_theme.dart';
import '../notifications/notification_screen.dart';
import '../profile/profile_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override State<HomeTab> createState() => _HT();
}

class _HT extends State<HomeTab> {
  late AppState _as;
  String _q = '';
  bool _listening = false;

  void _r() { if (mounted) setState(() {}); }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listening) {
      _listening = true;
      _as = AppState.of(context);
      _as.exp.addListener(_r);
      _as.notifs.addListener(_r);
    }
  }

  @override
  void dispose() {
    _as.exp.removeListener(_r);
    _as.notifs.removeListener(_r);
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
    backgroundColor: ctx.cBg,
    body: CustomScrollView(slivers: [
      _appBar(ctx),
      SliverToBoxAdapter(child: _summary(ctx)),
      SliverToBoxAdapter(child: _insights(ctx)),
      SliverToBoxAdapter(child: _weekBar(ctx)),
      SliverToBoxAdapter(child: _catRow(ctx)),
      SliverToBoxAdapter(child: _search(ctx)),
      SliverToBoxAdapter(child: _listHdr(ctx)),
      _expList(ctx),
      const SliverToBoxAdapter(child: SizedBox(height: 110)),
    ]),
  );

  Widget _appBar(BuildContext ctx) {
    final s  = AppState.of(ctx);
    final u  = s.users.current;
    final nr = s.notifs.unread;
    return SliverAppBar(
      floating: true, snap: true,
      backgroundColor: ctx.cCard, elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Overview', style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w800, fontSize: 20)),
        Text("Here's what happened today",
            style: TextStyle(color: ctx.cTxt2, fontSize: 11, fontWeight: FontWeight.w400)),
      ]),
      actions: [
        Stack(clipBehavior: Clip.none, children: [
          _iconBtn(ctx, Icons.notifications_outlined, () =>
              Navigator.push(ctx, MaterialPageRoute(builder: (_) => const NotificationScreen()))),
          if (nr > 0) Positioned(right: 8, top: 8,
            child: Container(width: 8, height: 8,
              decoration: const BoxDecoration(color: kP, shape: BoxShape.circle))),
        ]),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: Padding(padding: const EdgeInsets.only(right: 16, left: 4),
            child: CircleAvatar(radius: 18, backgroundColor: kP.withOpacity(.15),
              child: Text(u?.avatar ?? '?',
                  style: const TextStyle(color: kP, fontWeight: FontWeight.w800, fontSize: 12))))),
      ],
    );
  }

  Widget _iconBtn(BuildContext ctx, IconData icon, VoidCallback fn) => GestureDetector(
    onTap: fn,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: ctx.cCard2, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ctx.cBord)),
      child: Icon(icon, color: ctx.cTxt2, size: 18)));

  Widget _summary(BuildContext ctx) {
    final exp   = AppState.of(ctx).exp;
    final total = exp.totalMonth;
    final over  = total > exp.budget;
    final pct   = (total / exp.budget).clamp(0.0, 1.0);
    final now   = DateTime.now();
    const mn = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: cardDeco(ctx, radius: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _statBox(ctx, 'Spending', '${exp.cur}${total.toStringAsFixed(0)}',
              over ? '⚠ Over' : '-${((1-pct)*100).toInt()}% left',
              over ? kRed : kGreen, Icons.trending_up_rounded),
          const SizedBox(width: 12),
          _statBox(ctx, 'Budget', '${exp.cur}${exp.budget.toInt()}',
              '${exp.expenses.where((e)=>e.date.month==now.month).length} txns  ${mn[now.month]}',
              kP, Icons.savings_rounded),
        ]),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Budget used', style: TextStyle(color: ctx.cTxt2, fontSize: 12)),
          Text('${(pct*100).toInt()}%',
              style: TextStyle(color: over ? kRed : kP, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        Stack(children: [
          Container(height: 6, decoration: BoxDecoration(
              color: ctx.cCard2, borderRadius: BorderRadius.circular(4))),
          FractionallySizedBox(widthFactor: pct, child: Container(height: 6,
              decoration: BoxDecoration(
                color: over ? kRed : kP,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [BoxShadow(color: kP.withOpacity(.4), blurRadius: 8)],
              ))),
        ]),
      ]),
    );
  }

  Widget _statBox(BuildContext ctx, String label, String value, String sub, Color accent, IconData icon) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: ctx.cCard2, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ctx.cBord)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: accent.withOpacity(.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: accent, size: 14)),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: ctx.cTxt2, fontSize: 11)),
          ]),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w800, fontSize: 22, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600)),
        ])));

  Widget _insights(BuildContext ctx) {
    final exp  = AppState.of(ctx).exp;
    final all  = exp.expenses.toList();
    final avg  = Analytics.dailyAvg(all);
    final top  = Analytics.topCat(all);
    final peak = Analytics.peakDay(all);
    return Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(children: [
        _insCard(ctx, '${exp.cur}${avg.toInt()}', 'Daily Avg',   Icons.today_rounded,                Colors.blue.shade300),
        const SizedBox(width: 10),
        _insCard(ctx, top,                        'Top Cat',     Icons.star_rounded,                 kP),
        const SizedBox(width: 10),
        _insCard(ctx, peak,                       'Peak Day',    Icons.local_fire_department_rounded, kRed),
      ]));
  }

  Widget _insCard(BuildContext ctx, String v, String l, IconData icon, Color c) => Expanded(
    child: Container(padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: cardDeco(ctx, radius: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: c.withOpacity(.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: c, size: 14)),
        const SizedBox(height: 10),
        Text(v, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: ctx.cTxt),
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(l, style: TextStyle(color: ctx.cTxt2, fontSize: 10)),
      ])));

  Widget _weekBar(BuildContext ctx) {
    final exp   = AppState.of(ctx).exp;
    final trend = Analytics.weekly(exp.expenses.toList());
    final mx    = trend.map((d) => d['total'] as double).reduce((a, b) => a > b ? a : b);
    if (mx == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: cardDeco(ctx, radius: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('This Week', style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w700, fontSize: 14)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: kP.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
            child: Text('${exp.cur}${trend.map((d) => d['total'] as double).reduce((a,b)=>a+b).toInt()}',
                style: const TextStyle(color: kP, fontSize: 11, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 14),
        SizedBox(height: 110, child: BarChart(BarChartData(
          barGroups: trend.asMap().entries.map((e) {
            final val = e.value['total'] as double;
            final isMax = val == mx;
            return BarChartGroupData(x: e.key, barRods: [BarChartRodData(
              toY: val,
              gradient: isMax ? const LinearGradient(
                  colors: [kD, kP], begin: Alignment.bottomCenter, end: Alignment.topCenter) : null,
              color: isMax ? null : ctx.cCard2,
              width: 20, borderRadius: BorderRadius.circular(6),
            )]);
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22,
                getTitlesWidget: (v, _) => Text(trend[v.toInt()]['day'] as String,
                    style: TextStyle(color: ctx.cTxt3, fontSize: 10, fontWeight: FontWeight.w600)))),
            leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true,
            getDrawingHorizontalLine: (_) => FlLine(color: ctx.cBord, strokeWidth: 1)),
        ))),
      ]));
  }

  Widget _catRow(BuildContext ctx) {
    final exp  = AppState.of(ctx).exp;
    final cats = exp.catTotals;
    if (cats.isEmpty) return const SizedBox.shrink();
    return SizedBox(height: 100, child: ListView(scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      children: cats.entries.map((e) {
        final info = catInfo(e.key);
        return Container(width: 80, margin: const EdgeInsets.only(right: 10),
          decoration: cardDeco(ctx, radius: 16),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: (info['color'] as Color).withOpacity(.15),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(info['icon'] as IconData, color: info['color'] as Color, size: 16)),
            const SizedBox(height: 6),
            Text(e.key, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: ctx.cTxt2),
                overflow: TextOverflow.ellipsis),
            Text('${exp.cur}${e.value.toInt()}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: info['color'] as Color)),
          ]));
      }).toList()));
  }

  Widget _search(BuildContext ctx) => Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: TextField(
      style: TextStyle(color: ctx.cTxt, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search expenses…',
        hintStyle: TextStyle(color: ctx.cTxt3),
        prefixIcon: Icon(Icons.search_rounded, color: ctx.cTxt3, size: 20),
        filled: true, fillColor: ctx.cCard,
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: ctx.cBord)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: ctx.cBord)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: kP, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 13)),
      onChanged: (v) => setState(() => _q = v.toLowerCase())));

  Widget _listHdr(BuildContext ctx) => Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('Recent Expenses', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ctx.cTxt)),
      Text('See all', style: const TextStyle(color: kP, fontWeight: FontWeight.w600, fontSize: 12)),
    ]));

  SliverList _expList(BuildContext ctx) {
    final all = AppState.of(ctx).exp.expenses
        .where((e) => _q.isEmpty || e.title.toLowerCase().contains(_q)
            || e.category.toLowerCase().contains(_q))
        .toList()..sort((a, b) => b.date.compareTo(a.date));
    if (all.isEmpty) return SliverList(delegate: SliverChildListDelegate([
      Padding(padding: const EdgeInsets.only(top: 40),
        child: Center(child: Column(children: [
          Icon(Icons.search_off_rounded, size: 48, color: ctx.cTxt3),
          const SizedBox(height: 10),
          Text('No expenses found', style: TextStyle(color: ctx.cTxt2, fontWeight: FontWeight.w500)),
        ]))),
    ]));
    return SliverList(delegate: SliverChildBuilderDelegate(
        (_, i) => ExpenseTile(e: all[i]), childCount: all.length));
  }
}
