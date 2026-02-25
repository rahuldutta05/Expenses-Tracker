import 'package:flutter/material.dart';
import '../../models/app_notif.dart';
import '../../services/app_state.dart';
import '../../theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override State<NotificationScreen> createState() => _NS();
}

class _NS extends State<NotificationScreen> {
  late AppState _as;
  bool _listening = false;
  void _r() { if (mounted) setState(() {}); }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listening) { _listening=true; _as=AppState.of(context); _as.notifs.addListener(_r); }
  }
  @override void dispose() { _as.notifs.removeListener(_r); super.dispose(); }

  @override
  Widget build(BuildContext ctx) {
    final s    = AppState.of(ctx).notifs;
    final list = s.all;
    return Scaffold(
      backgroundColor: ctx.cBg,
      appBar: AppBar(
        backgroundColor: ctx.cCard,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: ctx.cTxt2),
          onPressed: () => Navigator.pop(ctx)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Notifications', style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w800, fontSize: 18)),
          if (s.unread > 0)
            Text('${s.unread} unread', style: const TextStyle(color: kP, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
        actions: [
          if (list.isNotEmpty) ...[
            TextButton(onPressed: s.markAllRead,
              child: const Text('Mark all read', style: TextStyle(color: kP, fontSize: 12, fontWeight: FontWeight.w600))),
            IconButton(icon: const Icon(Icons.delete_sweep_rounded, color: kRed, size: 20),
              onPressed: () => _clearDlg(ctx, s)),
          ],
        ],
      ),
      body: list.isEmpty ? _empty(ctx) : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _Tile(n: list[i],
          onTap: () => s.markRead(list[i].id),
          onDelete: () => s.remove(list[i].id))),
    );
  }

  Widget _empty(BuildContext ctx) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: ctx.cCard, shape: BoxShape.circle, border: Border.all(color: ctx.cBord)),
      child: Icon(Icons.notifications_none_rounded, size: 44, color: ctx.cTxt3)),
    const SizedBox(height: 20),
    Text('All clear!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ctx.cTxt)),
    const SizedBox(height: 6),
    Text('Smart alerts will appear here.', style: TextStyle(color: ctx.cTxt2, fontSize: 14)),
  ]));

  void _clearDlg(BuildContext ctx, s) => showDialog(context: ctx,
    builder: (dlg) => AlertDialog(
      backgroundColor: ctx.cCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: ctx.cBord)),
      title: Text('Clear All', style: TextStyle(color: ctx.cTxt, fontWeight: FontWeight.w800)),
      content: Text('Delete all notifications?', style: TextStyle(color: ctx.cTxt2)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dlg),
          child: Text('Cancel', style: TextStyle(color: ctx.cTxt2))),
        ElevatedButton(onPressed: () { s.clear(); Navigator.pop(dlg); },
          style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Clear All')),
      ]));
}

class _Tile extends StatelessWidget {
  final AppNotif n; final VoidCallback onTap, onDelete;
  const _Tile({required this.n, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext ctx) {
    final info = _info(n.type);
    return Dismissible(key: Key(n.id), direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        decoration: BoxDecoration(color: kRed.withOpacity(.15), borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kRed.withOpacity(.4))),
        alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: kRed)),
      child: GestureDetector(onTap: onTap,
        child: Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: n.read ? ctx.cCard : (info['color'] as Color).withOpacity(.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: n.read ? ctx.cBord : (info['color'] as Color).withOpacity(.3)),
            boxShadow: ctx.isDark ? [] : [
              BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: (info['color'] as Color).withOpacity(.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(info['icon'] as IconData, color: info['color'] as Color, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(n.title, style: TextStyle(
                    fontWeight: n.read ? FontWeight.w600 : FontWeight.w800,
                    fontSize: 13, color: ctx.cTxt))),
                if (!n.read) Container(width: 7, height: 7,
                    decoration: BoxDecoration(color: info['color'] as Color, shape: BoxShape.circle)),
              ]),
              const SizedBox(height: 4),
              Text(n.body, style: TextStyle(color: ctx.cTxt2, fontSize: 12, height: 1.4)),
              const SizedBox(height: 6),
              Text(_ago(n.time), style: TextStyle(color: ctx.cTxt3, fontSize: 10)),
            ])),
          ]))));
  }

  Map<String,dynamic> _info(NType t) {
    switch(t) {
      case NType.added:      return{'icon':Icons.check_circle_rounded,  'color':kGreen};
      case NType.budgetWarn: return{'icon':Icons.warning_amber_rounded,  'color':Colors.orange};
      case NType.budgetOver: return{'icon':Icons.error_rounded,          'color':kRed};
      case NType.bigSpend:   return{'icon':Icons.bolt_rounded,           'color':Colors.deepPurple.shade300};
      case NType.summary:    return{'icon':Icons.bar_chart_rounded,      'color':kP};
      default:               return{'icon':Icons.notifications_rounded,  'color':Colors.grey};
    }
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24)   return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}
