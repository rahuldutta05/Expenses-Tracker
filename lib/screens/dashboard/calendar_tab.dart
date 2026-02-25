import 'package:flutter/material.dart';
import '../../services/app_state.dart';
import '../../widgets/expense_tile.dart';
import '../../theme/app_theme.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});
  @override State<CalendarTab> createState() => _CT();
}

class _CT extends State<CalendarTab> {
  late AppState _as;
  DateTime _month = DateTime.now();
  DateTime _sel   = DateTime.now();
  bool _listening = false;

  static const _months = ['January','February','March','April','May','June',
      'July','August','September','October','November','December'];
  static const _short  = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  static const _days   = ['M','T','W','T','F','S','S'];

  void _r() { if (mounted) setState(() {}); }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listening) { _listening=true; _as=AppState.of(context); _as.exp.addListener(_r); }
  }
  @override void dispose() { _as.exp.removeListener(_r); super.dispose(); }

  @override
  Widget build(BuildContext ctx) {
    final exp     = AppState.of(ctx).exp;
    final dayExps = exp.forDate(_sel);
    final total   = exp.dateTotal(_sel);
    final now     = DateTime.now();
    final isToday = _sel.year==now.year && _sel.month==now.month && _sel.day==now.day;

    return Scaffold(
      backgroundColor: ctx.cBg,
      body: Column(children: [
        Container(
          color: ctx.cCard,
          child: SafeArea(bottom: false, child: Column(children: [
            Padding(padding: const EdgeInsets.fromLTRB(20,16,20,12),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: ctx.cCard2, borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ctx.cBord)),
                  child: Row(children: [
                    const Icon(Icons.calendar_month_rounded, color: kP, size: 15),
                    const SizedBox(width: 8),
                    Text('${_months[_month.month-1]}',
                        style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, color: ctx.cTxt2, size: 16),
                  ]),
                ),
                const Spacer(),
                _navBtn(ctx, Icons.chevron_left_rounded,
                    () => setState(() => _month = DateTime(_month.year, _month.month-1))),
                const SizedBox(width: 4),
                _navBtn(ctx, Icons.chevron_right_rounded,
                    () => setState(() => _month = DateTime(_month.year, _month.month+1))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: ctx.cCard2, borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ctx.cBord)),
                  child: Row(children: [
                    Icon(Icons.filter_list_rounded, color: ctx.cTxt2, size: 15),
                    const SizedBox(width: 6),
                    Text('Filter', style: TextStyle(color: ctx.cTxt2, fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: _days.map((d) => Expanded(child: Center(child: Text(d,
                  style: TextStyle(color: ctx.cTxt3, fontSize: 12, fontWeight: FontWeight.w600))))).toList())),
            const SizedBox(height: 8),
            Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: _grid(ctx, exp)),
          ])),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          decoration: BoxDecoration(color: ctx.cBg,
              border: Border(bottom: BorderSide(color: ctx.cBord))),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isToday ? 'Today' : _weekdayName(_sel.weekday),
                  style: TextStyle(color: ctx.cTxt2, fontSize: 12, fontWeight: FontWeight.w600)),
              Text('${_short[_sel.month-1]} ${_sel.day.toString().padLeft(2,'0')}',
                  style: TextStyle(color: ctx.cTxt, fontSize: 18, fontWeight: FontWeight.w800)),
            ]),
            const Spacer(),
            if (total > 0) Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(color: kP.withOpacity(.12), borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kP.withOpacity(.3))),
              child: Text('${exp.cur}${total.toInt()}',
                  style: const TextStyle(color: kP, fontWeight: FontWeight.w700, fontSize: 13))),
            const SizedBox(width: 8),
            GestureDetector(onTap: () => showAddSheet(context),
              child: Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: kP, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 16))),
          ])),
        Expanded(child: dayExps.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: ctx.cCard, shape: BoxShape.circle,
                      border: Border.all(color: ctx.cBord)),
                  child: Icon(Icons.receipt_long_rounded, size: 36, color: ctx.cTxt3)),
                const SizedBox(height: 16),
                Text('No expenses', style: TextStyle(color: ctx.cTxt2, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Tap + to add one', style: TextStyle(color: ctx.cTxt3, fontSize: 13)),
              ]))
            : ListView.builder(padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: dayExps.length,
                itemBuilder: (_, i) => _DayExpRow(e: dayExps[i], cur: exp.cur))),
      ]),
    );
  }

  Widget _navBtn(BuildContext ctx, IconData icon, VoidCallback fn) => GestureDetector(onTap: fn,
    child: Container(padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: ctx.cCard2, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ctx.cBord)),
      child: Icon(icon, color: ctx.cTxt2, size: 16)));

  Widget _grid(BuildContext ctx, exp) {
    final first  = DateTime(_month.year, _month.month, 1);
    final last   = DateTime(_month.year, _month.month+1, 0);
    final offset = first.weekday - 1;
    final rows   = ((offset + last.day) / 7).ceil();
    return Column(children: List.generate(rows, (row) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: List.generate(7, (col) {
        final day = row*7 + col - offset + 1;
        if (day < 1 || day > last.day) return const Expanded(child: SizedBox(height: 42));
        final date   = DateTime(_month.year, _month.month, day);
        final sel    = date.year==_sel.year && date.month==_sel.month && date.day==_sel.day;
        final today  = date.year==DateTime.now().year && date.month==DateTime.now().month && date.day==DateTime.now().day;
        final hasExp = exp.forDate(date).isNotEmpty;
        return Expanded(child: GestureDetector(onTap: () => setState(() => _sel = date),
          child: AnimatedContainer(duration: const Duration(milliseconds: 160),
            height: 42, margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: sel ? kP : today ? kP.withOpacity(.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: today && !sel ? Border.all(color: kP.withOpacity(.4)) : null),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${day.toString().padLeft(2,'0')}', style: TextStyle(
                  color: sel ? Colors.white : today ? kP : ctx.cTxt2,
                  fontWeight: sel || today ? FontWeight.w800 : FontWeight.w400, fontSize: 13)),
              if (hasExp) ...[
                const SizedBox(height: 2),
                Container(width: 4, height: 4, decoration: BoxDecoration(
                    color: sel ? Colors.white70 : kP, shape: BoxShape.circle)),
              ],
            ]))));
      })),
    )));
  }

  String _weekdayName(int w) {
    const n = ['','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return n[w];
  }
}

class _DayExpRow extends StatelessWidget {
  final e; final String cur;
  const _DayExpRow({required this.e, required this.cur});

  @override
  Widget build(BuildContext ctx) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 52, child: Padding(padding: const EdgeInsets.only(top: 14),
        child: Text(_fmtTime(e.date), style: TextStyle(color: ctx.cTxt3, fontSize: 10,
            fontWeight: FontWeight.w500), textAlign: TextAlign.right))),
      const SizedBox(width: 12),
      Column(children: [
        const SizedBox(height: 18),
        Container(width: 3, height: 3, decoration: const BoxDecoration(color: kP, shape: BoxShape.circle)),
        Container(width: 1, height: 44, color: kBord),
      ]),
      const SizedBox(width: 14),
      Expanded(child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: cardDeco(ctx, radius: 14),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.title, style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w600, fontSize: 13)),
            if (e.note.isNotEmpty) ...[const SizedBox(height: 2),
              Text(e.note, style: TextStyle(color: ctx.cTxt3, fontSize: 11), overflow: TextOverflow.ellipsis)],
          ])),
          Text('$cur${e.amount.toInt()}', style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w800, fontSize: 14)),
        ]))),
    ]),
  );

  String _fmtTime(DateTime d) {
    final h  = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m  = d.minute.toString().padLeft(2,'0');
    final ap = d.hour < 12 ? 'AM' : 'PM';
    return '$h:$m\n$ap';
  }
}
