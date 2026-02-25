import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/app_state.dart';
import '../utils/cats.dart';
import '../theme/app_theme.dart';

void showAddSheet(BuildContext ctx, {Expense? existing}) =>
    showModalBottomSheet(
      context: ctx, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddExpenseSheet(existing: existing));

// ─── Expense Tile ─────────────────────────────────────────────────────────────
class ExpenseTile extends StatelessWidget {
  final Expense e;
  const ExpenseTile({super.key, required this.e});

  void _del(BuildContext ctx) => showDialog(context: ctx,
    builder: (dlg) => AlertDialog(
      backgroundColor: ctx.cCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: ctx.cBord)),
      title: Text('Delete Expense', style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w800)),
      content: Text('Remove "${e.title}"?', style: TextStyle(color: ctx.cTxt2)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dlg),
            child: Text('Cancel', style: TextStyle(color: ctx.cTxt2))),
        ElevatedButton(
          onPressed: () { AppState.of(ctx).exp.remove(e.id); Navigator.pop(dlg); },
          style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Delete')),
      ]));

  @override
  Widget build(BuildContext ctx) {
    final info = catInfo(e.category);
    final cur  = AppState.of(ctx).exp.cur;
    return Dismissible(
      key: Key(e.id),
      background:          _bg(ctx, Alignment.centerLeft,  kP,  Icons.edit_rounded,   'Edit'),
      secondaryBackground: _bg(ctx, Alignment.centerRight, kRed, Icons.delete_rounded, 'Delete'),
      confirmDismiss: (dir) async {
        dir == DismissDirection.startToEnd ? showAddSheet(ctx, existing: e) : _del(ctx);
        return false;
      },
      child: GestureDetector(
        onLongPress: () => _menu(ctx),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          padding: const EdgeInsets.all(14),
          decoration: cardDeco(ctx, radius: 16),
          child: Row(children: [
            Container(width: 46, height: 46,
              decoration: BoxDecoration(
                  color: (info['color'] as Color).withOpacity(.12),
                  borderRadius: BorderRadius.circular(13)),
              child: Icon(info['icon'] as IconData, color: info['color'] as Color, size: 21)),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.title, style: TextStyle(fontWeight: FontWeight.w600,
                  fontSize: 14, color: ctx.cTxt)),
              const SizedBox(height: 4),
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: (info['color'] as Color).withOpacity(.1),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(e.category, style: TextStyle(color: info['color'] as Color,
                      fontSize: 10, fontWeight: FontWeight.w600))),
                if (e.note.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Flexible(child: Text(e.note, style: TextStyle(color: ctx.cTxt3, fontSize: 11),
                      overflow: TextOverflow.ellipsis)),
                ],
              ]),
            ])),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$cur${e.amount.toInt()}',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: ctx.cTxt)),
              const SizedBox(height: 3),
              Text(_fmt(e.date), style: TextStyle(color: ctx.cTxt3, fontSize: 11)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _bg(BuildContext ctx, Alignment a, Color c, IconData icon, String l) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    decoration: BoxDecoration(color: c.withOpacity(.15), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withOpacity(.4))),
    alignment: a, padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: c, size: 22),
      const SizedBox(height: 4),
      Text(l, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    ]));

  void _menu(BuildContext ctx) => showModalBottomSheet(context: ctx,
    backgroundColor: Colors.transparent,
    builder: (sh) {
      final info = catInfo(e.category);
      final cur  = AppState.of(ctx).exp.cur;
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        decoration: cardDeco(ctx, radius: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: ctx.cBord, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: (info['color'] as Color).withOpacity(.12),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(info['icon'] as IconData, color: info['color'] as Color, size: 20)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.title, style: TextStyle(fontWeight: FontWeight.w700,
                    fontSize: 16, color: ctx.cTxt)),
                Text('$cur${e.amount.toInt()} · ${e.category}',
                    style: TextStyle(color: ctx.cTxt2, fontSize: 13)),
              ])),
            ])),
          Divider(height: 20, color: ctx.cBord),
          _mi(ctx, sh, Icons.edit_rounded,   'Edit',   kP,  () { Navigator.pop(sh); showAddSheet(ctx, existing: e); }),
          _mi(ctx, sh, Icons.delete_rounded, 'Delete', kRed, () { Navigator.pop(sh); _del(ctx); }),
          const SizedBox(height: 10),
        ]));
    });

  Widget _mi(BuildContext ctx, BuildContext sh, IconData icon, String l, Color c, VoidCallback fn) =>
    ListTile(onTap: fn,
      leading: Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: c.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: c, size: 18)),
      title: Text(l, style: TextStyle(fontWeight: FontWeight.w600, color: c, fontSize: 14)));

  String _fmt(DateTime d) {
    final n = DateTime.now();
    if (d.year==n.year && d.month==n.month && d.day==n.day) return 'Today';
    final y = n.subtract(const Duration(days: 1));
    if (d.year==y.year && d.month==y.month && d.day==y.day) return 'Yesterday';
    const m = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month]} ${d.day}';
  }
}

// ─── Add / Edit Sheet ─────────────────────────────────────────────────────────
class AddExpenseSheet extends StatefulWidget {
  final Expense? existing;
  const AddExpenseSheet({super.key, this.existing});
  @override State<AddExpenseSheet> createState() => _AES();
}
class _AES extends State<AddExpenseSheet> {
  late final TextEditingController _tc, _ac, _nc;
  late String _cat; late DateTime _date;
  bool get _edit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _tc  = TextEditingController(text: ex?.title ?? '');
    _ac  = TextEditingController(text: ex != null ? ex.amount.toInt().toString() : '');
    _nc  = TextEditingController(text: ex?.note ?? '');
    _cat = ex?.category ?? 'Food';
    _date = ex?.date ?? DateTime.now();
  }
  @override void dispose() { _tc.dispose(); _ac.dispose(); _nc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext ctx) {
    final cur = AppState.of(ctx).exp.cur;
    return Container(
      height: MediaQuery.of(ctx).size.height * .90,
      decoration: BoxDecoration(
        color: ctx.cCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(width: 44, height: 4,
            decoration: BoxDecoration(color: ctx.cBord, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Text(_edit ? 'Edit Expense' : 'New Expense',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ctx.cTxt)),
        const SizedBox(height: 20),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _amtBox(ctx, cur),            const SizedBox(height: 16),
            _field(ctx, _tc, 'Title',            Icons.title_rounded),   const SizedBox(height: 12),
            _catPicker(ctx),              const SizedBox(height: 12),
            _datePick(ctx),              const SizedBox(height: 12),
            _field(ctx, _nc, 'Note (optional)', Icons.notes_rounded),  const SizedBox(height: 28),
            _saveBtn(ctx),               const SizedBox(height: 28),
          ]))),
      ]));
  }

  Widget _amtBox(BuildContext ctx, String cur) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: ctx.isDark
            ? [kCard2, const Color(0xFF2A1F1A)]
            : [Colors.white, const Color(0xFFFFF3EE)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: ctx.isDark ? kBord : kP.withOpacity(.2)),
      boxShadow: [BoxShadow(color: kP.withOpacity(.1), blurRadius: 20, spreadRadius: 2)],
    ),
    child: Column(children: [
      Text('Amount', style: TextStyle(color: ctx.cTxt2, fontSize: 12, letterSpacing: .5)),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 12),
          child: Text(cur, style: const TextStyle(color: kP, fontSize: 22, fontWeight: FontWeight.w700))),
        IntrinsicWidth(child: TextField(controller: _ac, keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(color: ctx.cTxt, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1),
          decoration: InputDecoration(
            hintText: '0', hintStyle: TextStyle(color: ctx.cTxt3, fontSize: 48, fontWeight: FontWeight.w900),
            border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
            fillColor: Colors.transparent))),
      ]),
    ]));

  Widget _field(BuildContext ctx, TextEditingController c, String h, IconData icon) => TextField(
    controller: c,
    style: TextStyle(color: ctx.cTxt, fontSize: 14),
    decoration: InputDecoration(
      hintText: h, hintStyle: TextStyle(color: ctx.cTxt3),
      prefixIcon: Icon(icon, color: ctx.cTxt2, size: 18),
      filled: true, fillColor: ctx.cCard2,
      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: ctx.cBord)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: ctx.cBord)),
      focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: kP, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(vertical: 14)));

  Widget _catPicker(BuildContext ctx) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: ctx.cTxt2)),
    const SizedBox(height: 10),
    Wrap(spacing: 8, runSpacing: 8, children: kCats.map((cat) {
      final info = catInfo(cat); final sel = cat == _cat;
      return GestureDetector(onTap: () => setState(() => _cat = cat),
        child: AnimatedContainer(duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: sel ? (info['color'] as Color).withOpacity(.15) : ctx.cCard2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? info['color'] as Color : ctx.cBord, width: 1.5)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(info['icon'] as IconData,
                color: sel ? info['color'] as Color : ctx.cTxt3, size: 14),
            const SizedBox(width: 6),
            Text(cat, style: TextStyle(
                color: sel ? info['color'] as Color : ctx.cTxt2,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500, fontSize: 12)),
          ])));
    }).toList()),
  ]);

  Widget _datePick(BuildContext ctx) {
    const mn = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final t = _date.day == DateTime.now().day && _date.month == DateTime.now().month;
    return GestureDetector(
      onTap: () async {
        final p = await showDatePicker(context: context, initialDate: _date,
          firstDate: DateTime(2020), lastDate: DateTime.now(),
          builder: (ctx2, c) => Theme(data: ctx.isDark
            ? ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: kP, surface: kCard))
            : ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: kP)),
            child: c!));
        if (p != null) setState(() => _date = p);
      },
      child: Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: ctx.cCard2, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ctx.cBord)),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded, color: kP, size: 18),
          const SizedBox(width: 12),
          Text(t ? 'Today' : '${mn[_date.month]} ${_date.day}, ${_date.year}',
              style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w500, fontSize: 14)),
          const Spacer(),
          Icon(Icons.arrow_forward_ios_rounded, size: 13, color: ctx.cTxt3),
        ])));
  }

  Widget _saveBtn(BuildContext ctx) => SizedBox(width: double.infinity, height: 56,
    child: ElevatedButton(onPressed: _save,
      style: ElevatedButton.styleFrom(
        backgroundColor: kP, foregroundColor: Colors.white,
        elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        shadowColor: kP.withOpacity(.4),
      ),
      child: Text(_edit ? 'Save Changes' : 'Save Expense',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))));

  Future<void> _save() async {
    final t = _tc.text.trim(); final a = double.tryParse(_ac.text.trim()) ?? 0;
    if (t.isEmpty || a <= 0) return;
    final ex = Expense(
      id: _edit ? widget.existing!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      title: t, amount: a, category: _cat, date: _date, note: _nc.text.trim());
    final s = AppState.of(context).exp;
    if (_edit) await s.update(ex); else await s.add(ex);
    if (mounted) Navigator.pop(context);
  }
}
