import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// ─── GLOBALS ──────────────────────────────────────────────────────────────────
late final AppState appState;
final ValueNotifier<bool> isDarkMode = ValueNotifier(false);

void main() {
  appState = AppState();
  runApp(const MyApp());
}

// ═══════════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String note;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
  });

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? note,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String avatar; // emoji avatar
  double monthlyBudget;
  String currency;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    this.monthlyBudget = 10000,
    this.currency = '₹',
  });
}

enum NotificationType { expenseAdded, budgetWarning, budgetExceeded, largeTransaction, reminder, monthlySummary }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// APP STATE (Multi-user)
// ═══════════════════════════════════════════════════════════════════════════════

class AppState extends ChangeNotifier {
  // ── Users ──
  final List<AppUser> _users = [
    AppUser(id: 'u1', name: 'Aryan Kapoor', email: 'aryan@email.com', avatar: '👨‍💻', monthlyBudget: 15000, currency: '₹'),
    AppUser(id: 'u2', name: 'Priya Sharma', email: 'priya@email.com', avatar: '👩‍🎨', monthlyBudget: 12000, currency: '₹'),
    AppUser(id: 'u3', name: 'Rahul Singh', email: 'rahul@email.com', avatar: '🧑‍🚀', monthlyBudget: 8000, currency: '₹'),
  ];

  String? _currentUserId;
  AppUser? get currentUser => _currentUserId == null
      ? null
      : _users.firstWhere((u) => u.id == _currentUserId, orElse: () => _users.first);
  List<AppUser> get allUsers => List.unmodifiable(_users);

  // ── Expenses per user ──
  final Map<String, List<Expense>> _expensesMap = {
    'u1': [
      Expense(id: '1', title: 'Grocery Shopping', amount: 850, category: 'Food', date: DateTime.now().subtract(const Duration(days: 1)), note: 'Weekly groceries'),
      Expense(id: '2', title: 'Uber Ride', amount: 220, category: 'Transport', date: DateTime.now().subtract(const Duration(days: 1))),
      Expense(id: '3', title: 'Netflix', amount: 499, category: 'Entertainment', date: DateTime.now().subtract(const Duration(days: 3))),
      Expense(id: '4', title: 'New Shoes', amount: 2499, category: 'Shopping', date: DateTime.now().subtract(const Duration(days: 5))),
      Expense(id: '5', title: 'Restaurant Dinner', amount: 1200, category: 'Food', date: DateTime.now()),
      Expense(id: '6', title: 'Doctor Visit', amount: 500, category: 'Health', date: DateTime.now().subtract(const Duration(days: 2))),
      Expense(id: '7', title: 'Electricity Bill', amount: 1800, category: 'Bills', date: DateTime.now().subtract(const Duration(days: 4))),
    ],
    'u2': [
      Expense(id: '8', title: 'Coffee & Snacks', amount: 340, category: 'Food', date: DateTime.now()),
      Expense(id: '9', title: 'Metro Pass', amount: 700, category: 'Transport', date: DateTime.now().subtract(const Duration(days: 2))),
      Expense(id: '10', title: 'Art Supplies', amount: 1600, category: 'Shopping', date: DateTime.now().subtract(const Duration(days: 3))),
    ],
    'u3': [
      Expense(id: '11', title: 'Gym Membership', amount: 2000, category: 'Health', date: DateTime.now().subtract(const Duration(days: 1))),
      Expense(id: '12', title: 'Spotify', amount: 119, category: 'Entertainment', date: DateTime.now().subtract(const Duration(days: 5))),
    ],
  };

  // ── Notifications per user ──
  final Map<String, List<AppNotification>> _notificationsMap = {
    'u1': [
      AppNotification(id: 'n1', title: 'Large Transaction Alert', body: 'New Shoes cost ₹2499 — that\'s a big one!', type: NotificationType.largeTransaction, timestamp: DateTime.now().subtract(const Duration(days: 5))),
      AppNotification(id: 'n2', title: '80% Budget Reached', body: 'You\'ve used 80% of your monthly budget. Slow down!', type: NotificationType.budgetWarning, timestamp: DateTime.now().subtract(const Duration(days: 2))),
      AppNotification(id: 'n3', title: 'Monthly Summary - Jan', body: 'You spent ₹7268 across 7 categories last month.', type: NotificationType.monthlySummary, timestamp: DateTime.now().subtract(const Duration(days: 1)), isRead: true),
    ],
    'u2': [
      AppNotification(id: 'n4', title: 'Expense Added', body: 'Coffee & Snacks — ₹340 logged today.', type: NotificationType.expenseAdded, timestamp: DateTime.now()),
    ],
    'u3': [],
  };

  // ── Auth ──
  bool get isLoggedIn => _currentUserId != null;

  void login(String userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  void logout() {
    _currentUserId = null;
    notifyListeners();
  }

  void switchUser(String userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  void deleteAccount(String userId) {
    _users.removeWhere((u) => u.id == userId);
    _expensesMap.remove(userId);
    _notificationsMap.remove(userId);
    if (_currentUserId == userId) _currentUserId = null;
    notifyListeners();
  }

  // ── Expenses ──
  List<Expense> get expenses {
    if (_currentUserId == null) return [];
    return List.unmodifiable(_expensesMap[_currentUserId!] ?? []);
  }

  List<Expense> expensesForDate(DateTime date) {
    return expenses.where((e) => e.date.year == date.year && e.date.month == date.month && e.date.day == date.day).toList();
  }

  double totalForDate(DateTime date) => expensesForDate(date).fold(0, (s, e) => s + e.amount);

  double get totalThisMonth {
    final now = DateTime.now();
    return expenses.where((e) => e.date.year == now.year && e.date.month == now.month).fold(0, (s, e) => s + e.amount);
  }

  Map<String, double> get categoryTotals {
    final map = <String, double>{};
    for (final e in expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  // ── Analytics ──
  double get dailyAverage {
    if (expenses.isEmpty) return 0;
    final days = expenses.map((e) => DateTime(e.date.year, e.date.month, e.date.day)).toSet().length;
    return days == 0 ? 0 : totalThisMonth / days;
  }

  DateTime? get highestSpendingDay {
    if (expenses.isEmpty) return null;
    final dayMap = <DateTime, double>{};
    for (final e in expenses) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      dayMap[d] = (dayMap[d] ?? 0) + e.amount;
    }
    return dayMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String get topCategory {
    if (categoryTotals.isEmpty) return 'None';
    return categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  List<double> get weeklyTrend {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return expenses
          .where((e) => e.date.year == day.year && e.date.month == day.month && e.date.day == day.day)
          .fold(0.0, (s, e) => s + e.amount);
    });
  }

  void addExpense(Expense expense) {
    _expensesMap[_currentUserId!] ??= [];
    _expensesMap[_currentUserId!]!.add(expense);
    _checkSmartAlerts(expense);
    notifyListeners();
  }

  void removeExpense(String id) {
    _expensesMap[_currentUserId!]?.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void updateExpense(Expense updated) {
    final list = _expensesMap[_currentUserId!];
    if (list == null) return;
    final idx = list.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      list[idx] = updated;
      notifyListeners();
    }
  }

  // ── Smart Alerts ──
  void _checkSmartAlerts(Expense expense) {
    final uid = _currentUserId!;
    _notificationsMap[uid] ??= [];
    final notes = _notificationsMap[uid]!;
    final user = currentUser!;

    if (expense.amount >= 2000) {
      notes.add(AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '🚨 Large Transaction Alert',
        body: '${expense.title} cost ${user.currency}${expense.amount.toInt()} — that\'s a big one!',
        type: NotificationType.largeTransaction,
        timestamp: DateTime.now(),
      ));
    }

    final total = totalThisMonth;
    final pct = total / user.monthlyBudget;
    if (pct >= 1.0) {
      notes.add(AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_over',
        title: '⚠️ Budget Exceeded!',
        body: 'You\'ve exceeded your ${user.currency}${user.monthlyBudget.toInt()} monthly budget.',
        type: NotificationType.budgetExceeded,
        timestamp: DateTime.now(),
      ));
    } else if (pct >= 0.8) {
      notes.add(AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_warn',
        title: '⚡ 80% Budget Reached',
        body: 'You\'ve used ${(pct * 100).toInt()}% of your monthly budget.',
        type: NotificationType.budgetWarning,
        timestamp: DateTime.now(),
      ));
    }

    notes.add(AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString() + '_add',
      title: '✅ Expense Added',
      body: '${expense.title} — ${user.currency}${expense.amount.toInt()} logged.',
      type: NotificationType.expenseAdded,
      timestamp: DateTime.now(),
    ));
  }

  // ── Notifications ──
  List<AppNotification> get notifications {
    if (_currentUserId == null) return [];
    final list = List<AppNotification>.from(_notificationsMap[_currentUserId!] ?? []);
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  void markAllRead() {
    _notificationsMap[_currentUserId!]?.forEach((n) => n.isRead = true);
    notifyListeners();
  }

  void clearNotifications() {
    _notificationsMap[_currentUserId!] = [];
    notifyListeners();
  }

  // ── Settings ──
  void updateBudget(double budget) {
    currentUser?.monthlyBudget = budget;
    notifyListeners();
  }

  void updateCurrency(String currency) {
    currentUser?.currency = currency;
    notifyListeners();
  }

  void deleteAllExpenses() {
    _expensesMap[_currentUserId!] = [];
    notifyListeners();
  }

  Future<String> exportToCSV() async {
    final rows = <List<dynamic>>[
      ['Title', 'Amount', 'Category', 'Date', 'Note'],
      ...expenses.map((e) => [e.title, e.amount, e.category, e.date.toString(), e.note]),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/expenses_${currentUser?.name ?? 'export'}.csv');
    await file.writeAsString(csv);
    return file.path;
  }

  void addUser(AppUser user) {
    _users.add(user);
    _expensesMap[user.id] = [];
    _notificationsMap[user.id] = [];
    notifyListeners();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// THEME
// ═══════════════════════════════════════════════════════════════════════════════

class AppTheme {
  static const primary = Color(0xFF6C63FF);
  static const primaryLight = Color(0xFF9C94FF);
  static const primaryDark = Color(0xFF4B44CC);

  static ThemeData light() => ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light),
    scaffoldBackgroundColor: const Color(0xFFF8F7FF),
    cardColor: Colors.white,
  );

  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark),
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// CATEGORY HELPER
// ═══════════════════════════════════════════════════════════════════════════════

Map<String, dynamic> categoryInfo(String category) {
  switch (category) {
    case 'Food': return {'icon': Icons.restaurant_rounded, 'color': Colors.orange};
    case 'Transport': return {'icon': Icons.directions_car_rounded, 'color': Colors.blue};
    case 'Shopping': return {'icon': Icons.shopping_bag_rounded, 'color': Colors.pink};
    case 'Entertainment': return {'icon': Icons.movie_rounded, 'color': Colors.purple};
    case 'Health': return {'icon': Icons.favorite_rounded, 'color': Colors.red};
    case 'Bills': return {'icon': Icons.receipt_rounded, 'color': Colors.teal};
    default: return {'icon': Icons.category_rounded, 'color': Colors.grey};
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// APP
// ═══════════════════════════════════════════════════════════════════════════════

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    appState.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isDarkMode,
      builder: (context, dark, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: appState.isLoggedIn ? const MainScreen() : const LoginScreen(),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOGIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  bool _showCreateUser = false;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _selectedAvatar = '🧑';

  final List<String> _avatars = ['🧑', '👨‍💻', '👩‍🎨', '🧑‍🚀', '👩‍💼', '👨‍🎤', '🦸', '🧙', '🎯', '🚀'];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF2D1B69)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildLogo(),
                  const SizedBox(height: 48),
                  if (!_showCreateUser) ...[
                    _buildWelcome(),
                    const SizedBox(height: 32),
                    _buildUserList(),
                    const SizedBox(height: 24),
                    _buildCreateUserButton(),
                  ] else ...[
                    _buildCreateUserForm(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 16),
        const Text('ExpenseFlow', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
        const SizedBox(height: 6),
        Text('Smart expense tracking', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15)),
      ],
    );
  }

  Widget _buildWelcome() {
    return Column(
      children: [
        const Text('Choose Your Profile', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Select a user to continue', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
      ],
    );
  }

  Widget _buildUserList() {
    return Column(
      children: appState.allUsers.map((user) {
        return GestureDetector(
          onTap: () { appState.login(user.id); },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: Center(child: Text(user.avatar, style: const TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(user.email, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Budget', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                    Text('${user.currency}${user.monthlyBudget.toInt()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCreateUserButton() {
    return GestureDetector(
      onTap: () => setState(() => _showCreateUser = true),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_circle_rounded, color: AppTheme.primary, size: 22),
            SizedBox(width: 10),
            Text('Create New Profile', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateUserForm() {
    return Column(
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _showCreateUser = false),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            const Text('Create Profile', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 28),
        // Avatar picker
        Text('Choose Avatar', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: _avatars.map((a) {
            final selected = a == _selectedAvatar;
            return GestureDetector(
              onTap: () => setState(() => _selectedAvatar = a),
              child: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? Colors.white : Colors.transparent, width: 2),
                ),
                child: Center(child: Text(a, style: const TextStyle(fontSize: 24))),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _loginField(_nameCtrl, 'Full Name', Icons.person_rounded),
        const SizedBox(height: 14),
        _loginField(_emailCtrl, 'Email', Icons.email_rounded),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: _createUser,
          child: Container(
            width: double.infinity, height: 56,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: const Center(
              child: Text('Create Profile', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _loginField(TextEditingController ctrl, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: Colors.white70, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  void _createUser() {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (name.isEmpty) return;
    final user = AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email.isEmpty ? '${name.toLowerCase().replaceAll(' ', '.')}@email.com' : email,
      avatar: _selectedAvatar,
    );
    appState.addUser(user);
    appState.login(user.id);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    appState.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    appState.removeListener(_refresh);
    super.dispose();
  }

  final List<Widget> _screens = const [HomeTab(), CalendarTab(), StatsTab(), NotificationScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: KeyedSubtree(key: ValueKey(_selectedIndex), child: _screens[_selectedIndex]),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _selectedIndex <= 1 ? _buildFAB(context) : null,
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showAddExpenseSheet(context),
      backgroundColor: AppTheme.primary,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      elevation: 8,
    );
  }

  Widget _buildBottomNav() {
    final unread = appState.unreadCount;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) {
          setState(() => _selectedIndex = i);
          if (i == 3) appState.markAllRead();
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Calendar'),
          const BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Stats'),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_rounded),
                if (unread > 0)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Center(child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))),
                    ),
                  ),
              ],
            ),
            label: 'Alerts',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  void _showAddExpenseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddExpenseSheet(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HOME TAB
// ═══════════════════════════════════════════════════════════════════════════════

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    appState.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    appState.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(child: _buildSummaryCard()),
          SliverToBoxAdapter(child: _buildInsightRow()),
          SliverToBoxAdapter(child: _buildCategoryRow()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search expenses...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Expenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                  Text('${appState.expenses.length} total', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
          ),
          _buildExpenseList(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final user = appState.currentUser!;
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      backgroundColor: AppTheme.primary,
      elevation: 0,
      title: Row(
        children: [
          const Text('ExpenseFlow', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
        ],
      ),
      actions: [
        IconButton(
          icon: ValueListenableBuilder(
            valueListenable: isDarkMode,
            builder: (_, dark, __) => Icon(dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: Colors.white),
          ),
          onPressed: () => isDarkMode.value = !isDarkMode.value,
        ),
        IconButton(
          icon: const Icon(Icons.download_rounded, color: Colors.white),
          onPressed: () async {
            final path = await appState.exportToCSV();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Exported to $path'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppTheme.primary,
              ));
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: Center(child: Text(user.avatar, style: const TextStyle(fontSize: 18))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final user = appState.currentUser!;
    final total = appState.totalThisMonth;
    final overBudget = total > user.monthlyBudget;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monthly Spending', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('${user.currency}${total.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Text(user.name.split(' ').first, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(_monthName(DateTime.now().month), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryChip(Icons.receipt_long_rounded, '${appState.expenses.where((e) => e.date.month == DateTime.now().month).length} txns'),
              const SizedBox(width: 10),
              _summaryChip(Icons.trending_up_rounded, 'Avg ${user.currency}${appState.dailyAverage.toInt()}/day'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Budget: ${user.currency}${user.monthlyBudget.toInt()}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              Text(
                overBudget ? '⚠ Over budget!' : '${user.currency}${(user.monthlyBudget - total).toInt()} left',
                style: TextStyle(color: overBudget ? Colors.red.shade200 : Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (total / user.monthlyBudget).clamp(0.0, 1.0),
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation(overBudget ? Colors.red.shade300 : Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInsightRow() {
    final topCat = appState.topCategory;
    final catInf = categoryInfo(topCat);
    final highDay = appState.highestSpendingDay;
    final user = appState.currentUser!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _insightCard(
              icon: catInf['icon'] as IconData,
              color: catInf['color'] as Color,
              title: 'Top Category',
              value: topCat,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _insightCard(
              icon: Icons.calendar_today_rounded,
              color: Colors.indigo,
              title: 'Daily Avg',
              value: '${user.currency}${appState.dailyAverage.toInt()}',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _insightCard(
              icon: Icons.local_fire_department_rounded,
              color: Colors.deepOrange,
              title: 'Most Active',
              value: highDay != null ? '${_shortMonth(highDay.month)} ${highDay.day}' : 'N/A',
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightCard({required IconData icon, required Color color, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildCategoryRow() {
    final cats = appState.categoryTotals;
    final user = appState.currentUser!;
    if (cats.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        children: cats.entries.map((e) {
          final info = categoryInfo(e.key);
          return Container(
            width: 90,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: (info['color'] as Color).withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(info['icon'] as IconData, color: info['color'] as Color, size: 20),
                ),
                const SizedBox(height: 6),
                Text(e.key, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                Text('${user.currency}${e.value.toInt()}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: info['color'] as Color)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  SliverList _buildExpenseList() {
    final all = List.of(appState.expenses)
        .where((e) => searchQuery.isEmpty || e.title.toLowerCase().contains(searchQuery) || e.category.toLowerCase().contains(searchQuery))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (all.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(child: Column(children: [
              Icon(Icons.receipt_long_rounded, size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 10),
              Text('No expenses yet', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
            ])),
          ),
        ]),
      );
    }

    return SliverList(delegate: SliverChildBuilderDelegate((ctx, i) => ExpenseTile(expense: all[i]), childCount: all.length));
  }

  String _monthName(int m) => const ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m];
  String _shortMonth(int m) => _monthName(m);
}

// ═══════════════════════════════════════════════════════════════════════════════
// CALENDAR TAB
// ═══════════════════════════════════════════════════════════════════════════════

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    appState.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    appState.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        title: Text('Calendar', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 22)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildCalendar(),
          const Divider(height: 1),
          _buildDateHeader(),
          Expanded(child: _buildDayExpenses()),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(children: [_buildMonthHeader(), const SizedBox(height: 12), _buildDayLabels(), const SizedBox(height: 8), _buildDaysGrid()]),
    );
  }

  Widget _buildMonthHeader() {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1))),
        Text('${months[_focusedMonth.month - 1]} ${_focusedMonth.year}',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Theme.of(context).colorScheme.onSurface)),
        IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1))),
      ],
    );
  }

  Widget _buildDayLabels() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(children: days.map((d) => Expanded(child: Center(child: Text(d, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: d == 'Sun' ? Colors.red.shade300 : Colors.grey.shade500))))).toList());
  }

  Widget _buildDaysGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startOffset = firstDay.weekday - 1;
    final rows = ((startOffset + lastDay.day) / 7).ceil();

    return Column(children: List.generate(rows, (row) {
      return Row(children: List.generate(7, (col) {
        final cellIndex = row * 7 + col;
        final dayNum = cellIndex - startOffset + 1;
        if (dayNum < 1 || dayNum > lastDay.day) return const Expanded(child: SizedBox(height: 44));
        final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
        final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month && date.year == _selectedDate.year;
        final isToday = date.day == DateTime.now().day && date.month == DateTime.now().month && date.year == DateTime.now().year;
        final hasExpenses = appState.expensesForDate(date).isNotEmpty;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: Container(
              height: 44, margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : isToday ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$dayNum', style: TextStyle(
                  color: isSelected ? Colors.white : isToday ? AppTheme.primary : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w400, fontSize: 14,
                )),
                if (hasExpenses) Container(width: 4, height: 4, decoration: BoxDecoration(color: isSelected ? Colors.white70 : AppTheme.primary, shape: BoxShape.circle)),
              ]),
            ),
          ),
        );
      }));
    }));
  }

  Widget _buildDateHeader() {
    final total = appState.totalForDate(_selectedDate);
    final d = _selectedDate;
    final isToday = d.year == DateTime.now().year && d.month == DateTime.now().month && d.day == DateTime.now().day;
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final user = appState.currentUser!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(isToday ? 'Today, ${months[d.month]} ${d.day}' : '${months[d.month]} ${d.day}, ${d.year}',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
          if (total > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text('${user.currency}${total.toInt()}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
        ],
      ),
    );
  }

  Widget _buildDayExpenses() {
    final dayExpenses = appState.expensesForDate(_selectedDate);
    if (dayExpenses.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long_rounded, size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('No expenses for this day', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: dayExpenses.length,
      itemBuilder: (ctx, i) => ExpenseTile(expense: dayExpenses[i]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STATS TAB
// ═══════════════════════════════════════════════════════════════════════════════

class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor, elevation: 0,
        title: Text('Statistics', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 22)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeeklyTrend(context),
            const SizedBox(height: 24),
            Text('Spending by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 16),
            _buildPieChart(context),
            const SizedBox(height: 24),
            Text('Category Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 12),
            _buildCategoryList(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTrend(BuildContext context) {
    final trend = appState.weeklyTrend;
    final maxVal = trend.reduce(max);
    final user = appState.currentUser!;
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text('Last 7 days spending', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final val = trend[i];
                final barH = maxVal > 0 ? (val / maxVal) * 90 : 4.0;
                final dayIdx = now.subtract(Duration(days: 6 - i)).weekday - 1;
                final isToday = i == 6;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0) Text('${user.currency}${val.toInt()}', style: TextStyle(fontSize: 8, color: isToday ? AppTheme.primary : Colors.grey.shade400, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: barH.clamp(4.0, 90.0),
                          decoration: BoxDecoration(
                            color: isToday ? AppTheme.primary : AppTheme.primary.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(days[dayIdx], style: TextStyle(fontSize: 10, color: isToday ? AppTheme.primary : Colors.grey.shade400, fontWeight: isToday ? FontWeight.w700 : FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(BuildContext context) {
    final cats = appState.categoryTotals;
    if (cats.isEmpty) return const SizedBox.shrink();
    final total = cats.values.fold(0.0, (a, b) => a + b);
    final sections = cats.entries.map((cat) {
      final info = categoryInfo(cat.key);
      return PieChartSectionData(
        value: cat.value, color: info['color'] as Color,
        title: '${(cat.value / total * 100).toStringAsFixed(0)}%',
        radius: 70,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: SizedBox(height: 220, child: PieChart(PieChartData(sections: sections, sectionsSpace: 4, centerSpaceRadius: 40))),
    );
  }

  Widget _buildCategoryList(BuildContext context) {
    final cats = appState.categoryTotals;
    final total = cats.values.fold(0.0, (a, b) => a + b);
    final user = appState.currentUser!;
    return Column(children: cats.entries.map((e) {
      final info = categoryInfo(e.key);
      final pct = e.value / total;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: (info['color'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(info['icon'] as IconData, color: info['color'] as Color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(e.key, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
              Text('${user.currency}${e.value.toInt()}', style: TextStyle(fontWeight: FontWeight.w700, color: info['color'] as Color)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: pct, backgroundColor: Colors.grey.shade100, valueColor: AlwaysStoppedAnimation(info['color'] as Color), minHeight: 6),
            ),
          ])),
        ]),
      );
    }).toList());
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    appState.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    appState.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifications = appState.notifications;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor, elevation: 0,
        title: Text('Notifications', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w800, fontSize: 22)),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.w700)),
                  content: const Text('Remove all notifications?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Colors.grey.shade500))),
                    ElevatedButton(
                      onPressed: () { appState.clearNotifications(); Navigator.pop(ctx); },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
              child: const Text('Clear all', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('No notifications', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 6),
              Text('You\'re all caught up!', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (ctx, i) => _NotificationTile(notification: notifications[i]),
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final info = _notifInfo(notification.type);
    final isUnread = !notification.isRead;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? (info['color'] as Color).withOpacity(0.07) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: isUnread ? Border.all(color: (info['color'] as Color).withOpacity(0.25), width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: (info['color'] as Color).withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
            child: Center(child: Icon(info['icon'] as IconData, color: info['color'] as Color, size: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(notification.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Theme.of(context).colorScheme.onSurface))),
              if (isUnread) Container(width: 8, height: 8, decoration: BoxDecoration(color: info['color'] as Color, shape: BoxShape.circle)),
            ]),
            const SizedBox(height: 4),
            Text(notification.body, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.4)),
            const SizedBox(height: 6),
            Text(_timeAgo(notification.timestamp), style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w500)),
          ])),
        ],
      ),
    );
  }

  Map<String, dynamic> _notifInfo(NotificationType type) {
    switch (type) {
      case NotificationType.expenseAdded: return {'icon': Icons.add_circle_rounded, 'color': Colors.green};
      case NotificationType.budgetWarning: return {'icon': Icons.warning_rounded, 'color': Colors.orange};
      case NotificationType.budgetExceeded: return {'icon': Icons.error_rounded, 'color': Colors.red};
      case NotificationType.largeTransaction: return {'icon': Icons.bolt_rounded, 'color': Colors.purple};
      case NotificationType.reminder: return {'icon': Icons.alarm_rounded, 'color': Colors.blue};
      case NotificationType.monthlySummary: return {'icon': Icons.bar_chart_rounded, 'color': AppTheme.primary};
    }
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROFILE SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    appState.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    appState.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = appState.currentUser!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildProfileHeader(user),
          SliverToBoxAdapter(child: _buildStatsRow(user)),
          SliverToBoxAdapter(child: _buildSettingsSection(user)),
          SliverToBoxAdapter(child: _buildSwitchUserSection()),
          SliverToBoxAdapter(child: _buildDangerSection(user)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(AppUser user) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Column(children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.5), width: 3)),
            child: Center(child: Text(user.avatar, style: const TextStyle(fontSize: 44))),
          ),
          const SizedBox(height: 14),
          Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(user.email, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text('${user.currency}${user.monthlyBudget.toInt()} / month budget', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }

  Widget _buildStatsRow(AppUser user) {
    final total = appState.totalThisMonth;
    final txCount = appState.expenses.where((e) => e.date.month == DateTime.now().month).length;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        _statBox('This Month', '${user.currency}${total.toInt()}', Icons.calendar_month_rounded, Colors.blue),
        const SizedBox(width: 12),
        _statBox('Transactions', '$txCount', Icons.receipt_long_rounded, Colors.green),
        const SizedBox(width: 12),
        _statBox('Categories', '${appState.categoryTotals.length}', Icons.category_rounded, Colors.orange),
      ]),
    );
  }

  Widget _statBox(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildSettingsSection(AppUser user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
        ),
        _settingsTile(
          icon: Icons.account_balance_wallet_rounded, color: AppTheme.primary,
          title: 'Monthly Budget', subtitle: '${user.currency}${user.monthlyBudget.toInt()}',
          onTap: () => _showBudgetDialog(user),
        ),
        _settingsTile(
          icon: Icons.currency_exchange_rounded, color: Colors.teal,
          title: 'Currency', subtitle: user.currency,
          onTap: () => _showCurrencyDialog(user),
        ),
        _settingsTile(
          icon: isDarkMode.value ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: Colors.indigo,
          title: 'Dark Mode', subtitle: isDarkMode.value ? 'Enabled' : 'Disabled',
          trailing: Switch(
            value: isDarkMode.value, onChanged: (v) { isDarkMode.value = v; setState(() {}); },
            activeColor: AppTheme.primary,
          ),
        ),
        _settingsTile(
          icon: Icons.download_rounded, color: Colors.green,
          title: 'Export Data', subtitle: 'Download as CSV',
          onTap: () async {
            final path = await appState.exportToCSV();
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to $path'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
          },
        ),
      ]),
    );
  }

  Widget _buildSwitchUserSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('Other Profiles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
        ),
        ...appState.allUsers.where((u) => u.id != appState.currentUser!.id).map((user) {
          return GestureDetector(
            onTap: () => appState.switchUser(user.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Row(children: [
                Container(width: 46, height: 46, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle), child: Center(child: Text(user.avatar, style: const TextStyle(fontSize: 22)))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
                  Text(user.email, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Text('Switch', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ]),
            ),
          );
        }).toList(),
        _settingsTile(
          icon: Icons.logout_rounded, color: Colors.orange,
          title: 'Logout', subtitle: 'Back to login screen',
          onTap: () => appState.logout(),
        ),
      ]),
    );
  }

  Widget _buildDangerSection(AppUser user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('Danger Zone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.red.shade400)),
        ),
        _settingsTile(
          icon: Icons.delete_sweep_rounded, color: Colors.red,
          title: 'Delete All Expenses', subtitle: 'Cannot be undone',
          onTap: () => showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Delete All Expenses', style: TextStyle(fontWeight: FontWeight.w700)),
              content: const Text('This will permanently remove all your expense data.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Colors.grey.shade500))),
                ElevatedButton(
                  onPressed: () { appState.deleteAllExpenses(); Navigator.pop(ctx); },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ),
        ),
        _settingsTile(
          icon: Icons.person_remove_rounded, color: Colors.red.shade700,
          title: 'Delete Account', subtitle: 'Permanently remove this profile',
          onTap: () => showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w700)),
              content: Text('Permanently delete ${user.name}\'s profile and all data?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Colors.grey.shade500))),
                ElevatedButton(
                  onPressed: () { Navigator.pop(ctx); appState.deleteAccount(user.id); },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Delete Account'),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _settingsTile({required IconData icon, required Color color, required String title, required String subtitle, VoidCallback? onTap, Widget? trailing}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ])),
          trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        ]),
      ),
    );
  }

  void _showBudgetDialog(AppUser user) {
    final ctrl = TextEditingController(text: user.monthlyBudget.toInt().toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Monthly Budget', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl, keyboardType: TextInputType.number,
          decoration: InputDecoration(prefixText: '${user.currency} ', hintText: 'Enter amount', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Colors.grey.shade500))),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text);
              if (val != null && val > 0) { appState.updateBudget(val); }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog(AppUser user) {
    final currencies = ['₹', '\$', '€', '£', '¥', '₩', '₿'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Currency', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Wrap(
          spacing: 10, runSpacing: 10,
          children: currencies.map((c) {
            final selected = c == user.currency;
            return GestureDetector(
              onTap: () { appState.updateCurrency(c); Navigator.pop(ctx); },
              child: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : Colors.grey.shade100,
                  shape: BoxShape.circle, border: Border.all(color: selected ? AppTheme.primary : Colors.transparent),
                ),
                child: Center(child: Text(c, style: TextStyle(fontSize: 20, color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w700))),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXPENSE TILE
// ═══════════════════════════════════════════════════════════════════════════════

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  const ExpenseTile({super.key, required this.expense});

  void _openEdit(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => AddExpenseSheet(existingExpense: expense));
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Expense', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Remove "${expense.title}" permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Colors.grey.shade500))),
          ElevatedButton(
            onPressed: () { appState.removeExpense(expense.id); Navigator.pop(ctx); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = categoryInfo(expense.category);
    final user = appState.currentUser!;
    return Dismissible(
      key: Key(expense.id),
      background: _swipeBg(alignment: Alignment.centerLeft, color: AppTheme.primary, icon: Icons.edit_rounded, label: 'Edit'),
      secondaryBackground: _swipeBg(alignment: Alignment.centerRight, color: Colors.red.shade400, icon: Icons.delete_rounded, label: 'Delete'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) { _openEdit(context); return false; }
        else { _confirmDelete(context); return false; }
      },
      child: GestureDetector(
        onLongPress: () => _showActionMenu(context),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))],
          ),
          child: Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: (info['color'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(info['icon'] as IconData, color: info['color'] as Color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(expense.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 2),
              Row(children: [
                Text(expense.category, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                if (expense.note.isNotEmpty) ...[
                  Text('  ·  ', style: TextStyle(color: Colors.grey.shade400)),
                  Flexible(child: Text(expense.note, style: TextStyle(color: Colors.grey.shade400, fontSize: 11), overflow: TextOverflow.ellipsis)),
                ],
              ]),
            ])),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${user.currency}${expense.amount.toInt()}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 2),
              Text(_formatDate(expense.date), style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            ]),
            const SizedBox(width: 4),
            Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey.shade400),
          ]),
        ),
      ),
    );
  }

  Widget _swipeBg({required Alignment alignment, required Color color, required IconData icon, required String label}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  void _showActionMenu(BuildContext context) {
    final user = appState.currentUser!;
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(categoryInfo(expense.category)['icon'] as IconData, color: AppTheme.primary, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(expense.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                Text('${user.currency}${expense.amount.toInt()} · ${expense.category}', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ])),
            ]),
          ),
          const Divider(height: 24),
          _actionTile(ctx, Icons.edit_rounded, 'Edit Expense', AppTheme.primary, () { Navigator.pop(ctx); _openEdit(context); }),
          _actionTile(ctx, Icons.delete_rounded, 'Delete Expense', Colors.red.shade400, () { Navigator.pop(ctx); _confirmDelete(context); }),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _actionTile(BuildContext ctx, IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 15)),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) return 'Today';
    final yesterday = now.subtract(const Duration(days: 1));
    if (d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day) return 'Yesterday';
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month]} ${d.day}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ADD / EDIT EXPENSE SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class AddExpenseSheet extends StatefulWidget {
  final Expense? existingExpense;
  const AddExpenseSheet({super.key, this.existingExpense});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late String _selectedCategory;
  late DateTime _selectedDate;

  bool get _isEditing => widget.existingExpense != null;

  final List<String> _categories = ['Food', 'Transport', 'Shopping', 'Entertainment', 'Health', 'Bills', 'Other'];

  @override
  void initState() {
    super.initState();
    final e = widget.existingExpense;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _amountCtrl = TextEditingController(text: e != null ? e.amount.toInt().toString() : '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _selectedCategory = e?.category ?? 'Food';
    _selectedDate = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _amountCtrl.dispose(); _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Text(_isEditing ? 'Edit Expense' : 'New Expense', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildAmountInput(),
              const SizedBox(height: 20),
              _buildTextField(_titleCtrl, 'Title', Icons.title_rounded),
              const SizedBox(height: 16),
              _buildCategoryPicker(),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              _buildTextField(_noteCtrl, 'Note (optional)', Icons.notes_rounded),
              const SizedBox(height: 32),
              _buildSaveButton(),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildAmountInput() {
    final user = appState.currentUser!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]), borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        const Text('Amount', style: TextStyle(color: Colors.white70, fontSize: 13)),
        Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 8), child: Text(user.currency, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700))),
          IntrinsicWidth(
            child: TextField(
              controller: _amountCtrl, keyboardType: TextInputType.number, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1),
              decoration: const InputDecoration(hintText: '0', hintStyle: TextStyle(color: Colors.white38, fontSize: 44, fontWeight: FontWeight.w800), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: _categories.map((cat) {
          final info = categoryInfo(cat);
          final isSelected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? (info['color'] as Color).withOpacity(0.15) : Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? info['color'] as Color : Colors.transparent, width: 1.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(info['icon'] as IconData, color: isSelected ? info['color'] as Color : Colors.grey.shade400, size: 16),
                const SizedBox(width: 6),
                Text(cat, style: TextStyle(color: isSelected ? info['color'] as Color : Colors.grey.shade600, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
              ]),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _buildDatePicker() {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final isToday = _selectedDate.day == DateTime.now().day && _selectedDate.month == DateTime.now().month;
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context, initialDate: _selectedDate,
          firstDate: DateTime(2020), lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.primary)), child: child!),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Text(isToday ? 'Today' : '${months[_selectedDate.month]} ${_selectedDate.day}, ${_selectedDate.year}',
              style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        ]),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: _save,
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
        child: Text(_isEditing ? 'Save Changes' : 'Save Expense', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    );
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (title.isEmpty || amount <= 0) return;

    final expense = Expense(
      id: _isEditing ? widget.existingExpense!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      title: title, amount: amount, category: _selectedCategory, date: _selectedDate, note: _noteCtrl.text.trim(),
    );

    if (_isEditing) {
      appState.updateExpense(expense);
    } else {
      appState.addExpense(expense);
    }
    Navigator.pop(context);
  }
}