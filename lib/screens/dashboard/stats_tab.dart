import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/app_state.dart';
import '../../utils/cats.dart';
import '../../utils/analytics.dart';
import '../../theme/app_theme.dart';

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});
  @override State<StatsTab> createState() => _ST();
}

class _ST extends State<StatsTab> {
  late AppState _as;
  int? _touchedIdx;
  bool _listening = false;

  void _r() { if (mounted) setState(() {}); }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listening) { _listening=true; _as=AppState.of(context); _as.exp.addListener(_r); }
  }
  @override void dispose() { _as.exp.removeListener(_r); super.dispose(); }

  @override
  Widget build(BuildContext ctx) {
    final exp   = AppState.of(ctx).exp;
    final cats  = exp.catTotals;
    final all   = exp.expenses.toList();
    final grand = cats.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: ctx.cBg,
      appBar: AppBar(
        backgroundColor: ctx.cCard,
        surfaceTintColor: Colors.transparent,
        title: Text('Statistics', style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w800, fontSize: 20)),
        actions: [
          Container(margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: ctx.cCard2, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ctx.cBord)),
            child: Text('This Month', style: TextStyle(color: ctx.cTxt2, fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
      body: grand == 0 ? _empty(ctx) : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _insightsRow(ctx, exp, all),  const SizedBox(height: 20),
          _sec(ctx, 'Spending Trend'),  const SizedBox(height: 12),
          _lineCard(ctx, all, exp.cur), const SizedBox(height: 20),
          _sec(ctx, 'Day-by-Day'),      const SizedBox(height: 12),
          _barCard(ctx, all, exp.cur),  const SizedBox(height: 20),
          _sec(ctx, 'Category Breakdown'), const SizedBox(height: 12),
          _pieRow(ctx, cats, grand, exp.cur),
        ])),
    );
  }

  Widget _empty(BuildContext ctx) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: ctx.cCard, shape: BoxShape.circle, border: Border.all(color: ctx.cBord)),
      child: Icon(Icons.bar_chart_rounded, size: 48, color: ctx.cTxt3)),
    const SizedBox(height: 20),
    Text('No data yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ctx.cTxt)),
    const SizedBox(height: 6),
    Text('Add expenses to see statistics.', style: TextStyle(color: ctx.cTxt2, fontSize: 14)),
  ]));

  Widget _sec(BuildContext ctx, String t) => Text(t,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ctx.cTxt2, letterSpacing: .3));

  Widget _insightsRow(BuildContext ctx, exp, List all) {
    final avg  = Analytics.dailyAvg(all);
    final top  = Analytics.topCat(all);
    final peak = Analytics.peakDay(all);
    final mtxn = all.where((e) => e.date.month == DateTime.now().month).length;
    return Row(children: [
      _insCard(ctx, '${exp.cur}${avg.toInt()}', 'Daily Avg',    Icons.today_rounded,    Colors.blue.shade300, '+avg'),
      const SizedBox(width: 10),
      _insCard(ctx, '$mtxn',                    'Transactions', Icons.receipt_rounded,  kGreen, '$mtxn txns'),
      const SizedBox(width: 10),
      _insCard(ctx, top,                        'Top Cat',      Icons.star_rounded,     kP, peak),
    ]);
  }

  Widget _insCard(BuildContext ctx, String v, String l, IconData icon, Color c, String sub) => Expanded(
    child: Container(padding: const EdgeInsets.all(14),
      decoration: cardDeco(ctx, radius: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: c.withOpacity(.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: c, size: 14)),
        const SizedBox(height: 10),
        Text(v, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: ctx.cTxt),
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Row(children: [
          Icon(Icons.arrow_upward_rounded, color: c, size: 10),
          const SizedBox(width: 2),
          Flexible(child: Text(sub, style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 1),
        Text(l, style: TextStyle(color: ctx.cTxt3, fontSize: 9)),
      ])));

  Widget _lineCard(BuildContext ctx, List all, String cur) {
    final trend  = Analytics.weekly(all);
    final points = trend.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), (e.value['total'] as double))).toList();
    final maxY   = points.map((p) => p.y).reduce((a, b) => a > b ? a : b);
    final total  = trend.map((d) => d['total'] as double).reduce((a,b)=>a+b);

    return Container(padding: const EdgeInsets.all(18),
      decoration: cardDeco(ctx, radius: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$cur${total.toStringAsFixed(0)}',
                style: TextStyle(color: ctx.cTxt, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            Row(children: [
              const Icon(Icons.arrow_upward_rounded, color: kGreen, size: 12),
              const SizedBox(width: 3),
              const Text('3.52%', style: TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              Text('From last week', style: TextStyle(color: ctx.cTxt3, fontSize: 11)),
            ]),
          ]),
        ]),
        const SizedBox(height: 16),
        SizedBox(height: 100, child: LineChart(LineChartData(
          lineBarsData: [LineChartBarData(
            spots: points, isCurved: true, curveSmoothness: 0.4,
            color: kGreen, barWidth: 2,
            belowBarData: BarAreaData(show: true,
                gradient: LinearGradient(colors: [kGreen.withOpacity(.25), kGreen.withOpacity(.0)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            dotData: const FlDotData(show: false),
          )],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 20,
                getTitlesWidget: (v, _) => Text(trend[v.toInt()]['day'] as String,
                    style: TextStyle(color: ctx.cTxt3, fontSize: 9)))),
            leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
          gridData: FlGridData(show: true,
              getDrawingHorizontalLine: (_) => FlLine(color: ctx.cBord, strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          minY: 0, maxY: maxY * 1.3,
        ))),
      ]));
  }

  Widget _barCard(BuildContext ctx, List all, String cur) {
    final trend  = Analytics.weekly(all);
    final maxVal = trend.map((d) => d['total'] as double).reduce((a,b) => a>b?a:b);
    final total  = trend.map((d) => d['total'] as double).reduce((a,b)=>a+b);

    return Container(padding: const EdgeInsets.all(18),
      decoration: cardDeco(ctx, radius: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$cur${total.toStringAsFixed(0)}',
                style: TextStyle(color: ctx.cTxt, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            Row(children: [
              const Icon(Icons.arrow_upward_rounded, color: kGreen, size: 12),
              const Text(' 7.89%', style: TextStyle(color: kGreen, fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              Text('From last month', style: TextStyle(color: ctx.cTxt3, fontSize: 10)),
            ]),
          ])),
          Row(children: [
            _legendDot(ctx, kP, 'Actual'),
            const SizedBox(width: 10),
            _legendDot(ctx, Colors.grey.withOpacity(.4), 'Target'),
          ]),
        ]),
        const SizedBox(height: 16),
        SizedBox(height: 120, child: maxVal == 0
          ? Center(child: Text('No data', style: TextStyle(color: ctx.cTxt3)))
          : BarChart(BarChartData(
              barGroups: trend.asMap().entries.map((e) {
                final val  = e.value['total'] as double;
                final mock = val * 0.7;
                return BarChartGroupData(x: e.key, barsSpace: 3, barRods: [
                  BarChartRodData(toY: val, color: kP, width: 10, borderRadius: BorderRadius.circular(4)),
                  BarChartRodData(toY: mock, color: ctx.cCard2, width: 10, borderRadius: BorderRadius.circular(4)),
                ]);
              }).toList(),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22,
                    getTitlesWidget: (v, _) => Text(trend[v.toInt()]['day'] as String,
                        style: TextStyle(color: ctx.cTxt3, fontSize: 9)))),
                leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: true,
                  getDrawingHorizontalLine: (_) => FlLine(color: ctx.cBord, strokeWidth: 1)),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => ctx.cCard2,
                  getTooltipItem: (g, _, rod, __) => BarTooltipItem(
                    '${trend[g.x]['day']}\n', TextStyle(color: ctx.cTxt2, fontSize: 10),
                    children: [TextSpan(text: rod.toY.toInt().toString(),
                        style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w800, fontSize: 12))]),
                ))))),
      ]));
  }

  Widget _legendDot(BuildContext ctx, Color c, String l) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(l, style: TextStyle(color: ctx.cTxt2, fontSize: 10)),
  ]);

  Widget _pieRow(BuildContext ctx, Map<String,double> cats, double grand, String cur) {
    final entries = cats.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
    return Column(children: [
      Container(padding: const EdgeInsets.all(18),
        decoration: cardDeco(ctx, radius: 20),
        child: Column(children: [
          SizedBox(height: 180, child: PieChart(PieChartData(
            sections: entries.asMap().entries.map((e) {
              final idx = e.key; final cat = e.value;
              final info = catInfo(cat.key); final touched = idx == _touchedIdx;
              return PieChartSectionData(
                value: cat.value, color: info['color'] as Color,
                title: '${(cat.value/grand*100).toStringAsFixed(0)}%',
                radius: touched ? 72 : 58,
                titleStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w800,
                    fontSize: touched ? 13 : 10));
            }).toList(),
            sectionsSpace: 2, centerSpaceRadius: 40,
            pieTouchData: PieTouchData(touchCallback: (_, resp) =>
                setState(() => _touchedIdx = resp?.touchedSection?.touchedSectionIndex))))),
          const SizedBox(height: 14),
          Wrap(spacing: 12, runSpacing: 6, alignment: WrapAlignment.center,
            children: entries.map((e) {
              final info = catInfo(e.key);
              return Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(
                    color: info['color'] as Color, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(e.key, style: TextStyle(fontSize: 10, color: ctx.cTxt2, fontWeight: FontWeight.w600)),
              ]);
            }).toList()),
        ])),
      const SizedBox(height: 12),
      ...entries.map((e) {
        final info = catInfo(e.key); final pct = e.value / grand;
        return Container(margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: cardDeco(ctx, radius: 14),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: (info['color'] as Color).withOpacity(.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(info['icon'] as IconData, color: info['color'] as Color, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(e.key, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ctx.cTxt)),
                Row(children: [
                  Text('$cur${e.value.toInt()}', style: TextStyle(fontWeight: FontWeight.w800,
                      fontSize: 13, color: info['color'] as Color)),
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: (info['color'] as Color).withOpacity(.12),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text('${(pct*100).toStringAsFixed(0)}%', style: TextStyle(
                        color: info['color'] as Color, fontSize: 9, fontWeight: FontWeight.w800))),
                ]),
              ]),
              const SizedBox(height: 8),
              Stack(children: [
                Container(height: 4, decoration: BoxDecoration(color: ctx.cCard2, borderRadius: BorderRadius.circular(3))),
                FractionallySizedBox(widthFactor: pct, child: Container(height: 4,
                    decoration: BoxDecoration(color: info['color'] as Color,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [BoxShadow(color: (info['color'] as Color).withOpacity(.5), blurRadius: 6)]))),
              ]),
            ])),
          ]));
      }),
    ]);
  }
}
