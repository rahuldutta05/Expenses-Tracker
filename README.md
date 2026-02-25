# 💸 ExpenseFlow

A beautifully designed, multi-user expense tracker built with Flutter. Features smart budget alerts, rich analytics, a calendar view, CSV export, and a seamless dark/light mode toggle — all with local persistence.

---

## ✨ Features

- **Multi-user support** — create and switch between multiple user profiles instantly
- **Smart alerts** — automatic notifications for large transactions, budget warnings (80%), and when you exceed your monthly limit
- **Analytics** — weekly spending trend charts, category breakdown pie chart, day-by-day bar chart, and key insight cards
- **Calendar view** — timeline-style expense history, browse by day with a custom grid calendar
- **Budget tracking** — visual progress bar showing how much of your monthly budget you've used
- **Dark / Light mode** — one-tap toggle in the bottom nav bar with smooth animated transitions
- **Local persistence** — all data saved to device storage via JSON (no backend required)
- **CSV export** — export all expenses to a `.csv` file
- **Swipe gestures** — swipe right to edit, left to delete any expense
- **Category system** — Food, Transport, Shopping, Entertainment, Health, Bills, Other
- **Multi-currency** — supports ₹, $, €, £, ¥

---

## 📁 Project Structure

```
lib/
├── main.dart                        # App entry point, theme setup, Google Fonts
├── theme/
│   └── app_theme.dart               # Design tokens, dark/light ThemeData, cardDeco helper
├── models/
│   ├── expense.dart                 # Expense model with JSON serialization
│   ├── user.dart                    # AppUser model
│   └── app_notif.dart               # AppNotif model + NType enum
├── services/
│   ├── app_state.dart               # InheritedWidget — dependency injection root
│   ├── expense_store.dart           # Expense CRUD, budget logic, CSV export
│   ├── user_store.dart              # Auth, user switching, profile updates
│   └── notif_store.dart             # Smart notification triggers and storage
├── screens/
│   ├── login/
│   │   └── login_screen.dart        # Login form + quick-switch user list
│   ├── dashboard/
│   │   ├── main_screen.dart         # Bottom nav, FAB, theme toggle pill
│   │   ├── home_tab.dart            # Overview: summary card, charts, expense list
│   │   ├── calendar_tab.dart        # Monthly calendar grid + day expense timeline
│   │   └── stats_tab.dart           # Line chart, bar chart, pie chart, category list
│   ├── notifications/
│   │   └── notification_screen.dart # Notification inbox with dismiss/mark-read
│   └── profile/
│       └── profile_screen.dart      # User profile, settings, account management
├── widgets/
│   └── expense_tile.dart            # Dismissible expense row + AddExpenseSheet modal
├── utils/
│   ├── cats.dart                    # Category metadata (icon, color), currency list
│   └── analytics.dart               # Daily avg, top category, peak day, weekly trend
└── database/
    └── db.dart                      # JSON file-based key-value store (no external DB)
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) `>=3.0.0`
- Dart `>=3.0.0`

### Installation

```bash
# 1. Clone or unzip the project
cd expenseflow

# 2. Install dependencies (also downloads Poppins font via Google Fonts)
flutter pub get

# 3. Run the app
flutter run
```

### Build for release

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

---

## 📦 Dependencies

| Package | Version | Purpose |
|---|---|---|
| `fl_chart` | ^0.68.0 | Line, bar, and pie charts |
| `csv` | ^6.0.0 | CSV file generation for export |
| `path_provider` | ^2.1.2 | Resolve device file system paths |
| `google_fonts` | ^6.1.0 | Poppins typeface (loaded at runtime) |
| `cupertino_icons` | ^1.0.6 | iOS-style icon set |

---

## 🎨 Design System

All color tokens and theme helpers live in `lib/theme/app_theme.dart`.

### Color Tokens

| Token | Dark | Light | Role |
|---|---|---|---|
| `kP` | `#FF6B35` | `#FF6B35` | Primary orange accent |
| `kGreen` | `#22C55E` | `#22C55E` | Positive / growth |
| `kRed` | `#EF4444` | `#EF4444` | Danger / over budget |
| `kSurf` | `#111118` | `#F8F7FF` | Scaffold background |
| `kCard` | `#1A1A24` | `#FFFFFF` | Card surface |
| `kTxt` | `#F0F0F8` | `#1A1A2E` | Primary text |
| `kTxt2` | `#8A8AA0` | `#6B6B8A` | Secondary text |

### Theme-Aware Helper

Use the `BuildContext` extension anywhere instead of hardcoding colors:

```dart
ctx.cCard   // card background (dark or light)
ctx.cTxt    // primary text color
ctx.cBord   // border color
ctx.isDark  // bool — current brightness
```

Use `cardDeco(ctx)` to get a consistent card `BoxDecoration` that includes a subtle shadow in light mode:

```dart
decoration: cardDeco(ctx, radius: 20),
```

---

## 🌗 Dark / Light Mode

The theme toggle is available in **three places**:

1. **Bottom nav bar** — animated pill button, always accessible
2. **Profile screen** — toggle tile with gradient sun/moon icon
3. **Settings screen** — same toggle tile

The `ValueNotifier<bool> dark` in `AppState` drives the `MaterialApp` `themeMode` — no restart needed, changes are instant.

> **Note:** Theme preference is currently in-memory and resets on restart. To persist it, save `dark.value` to `DB` in the toggle callback and load it during `_boot()` in `main.dart`.

---

## 💾 Data Persistence

Data is stored as JSON files in the app's documents directory via `path_provider`. The `DB` class in `lib/database/db.dart` provides a simple key-value API:

```dart
await DB.put('box_name', 'key', value);
final val = await DB.get('box_name', 'key');
await DB.del('box_name', 'key');
await DB.drop('box_name'); // delete entire box
```

Data is scoped per user (`exp_<uid>`, `notif_<uid>`) so profiles are fully isolated.

---

## 🔔 Smart Alerts

Notifications are automatically triggered when you add an expense:

| Condition | Alert |
|---|---|
| Any expense added | ✅ "Expense Recorded" |
| Amount ≥ 2,000 | ⚡ "Large Transaction" |
| Budget usage hits 80% | 🟡 "Budget Warning" |
| Budget exceeded (100%+) | 🔴 "Budget Exceeded" |

---

## 📋 Roadmap / Ideas

- [ ] Persist dark/light mode preference across restarts
- [ ] Recurring expenses
- [ ] Custom categories
- [ ] Monthly summary notification (scheduler)
- [ ] Hive integration for faster reads (`lib/database/db.dart` has a stub)
- [ ] Share CSV via system share sheet
- [ ] Biometric lock per profile
- [ ] Widget (home screen) for quick expense entry

---

## 📄 License

MIT — free to use, modify, and distribute.
