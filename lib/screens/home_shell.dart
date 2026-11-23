import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'categories_screen.dart';
import 'notifications_screen.dart';
import 'payment_flow.dart';
import 'settings_screens.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;

  void _onTap(int i) {
    if (i == 2) {
      showAddSheet(context);
    } else {
      setState(() => tab = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = switch (tab) {
      0 => const HomeTab(),
      1 => const HistoryTab(),
      3 => const ReportsTab(),
      _ => const ProfileTab(),
    };
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        TopBar(
          onBell: tab == 0
              ? () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const AlertsScreen()))
              : null,
        ),
        Expanded(child: body),
        BottomNav(current: tab, onTap: _onTap),
      ]),
    );
  }
}

void showAddSheet(BuildContext context) {
  Widget option(BuildContext ctx, String title, String sub, bool dark, VoidCallback go) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.pop(ctx);
        go();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: dark ? Colors.black : C.grey, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: sans(17, w: FontWeight.w700, color: dark ? Colors.white : Colors.black)),
          const SizedBox(height: 2),
          Text(sub, style: sans(14, color: dark ? const Color(0xFFC9C9C9) : C.text2)),
        ]),
      ),
    );
  }

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Add', style: serif(28)),
          const SizedBox(height: 16),
          option(ctx, 'Scan to pay', 'Scan a UPI QR, pay, and record it in one go.', true, () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanScreen()));
          }),
          const SizedBox(height: 12),
          option(ctx, 'Add manually', 'Cash, card, UPI or any other payment.', false, () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddManualScreen()));
          }),
        ]),
      ),
    ),
  );
}

// ------------------------------------------------------------------ Home

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final now = DateTime.now();
    final total = s.monthTotal;
    final budget = s.totalBudget;
    final spentBy = s.byCategoryIn(now);
    final rows = s.categories
        .where((c) => (c.limit ?? 0) > 0 || (spentBy[c.id] ?? 0) > 0)
        .toList()
      ..sort((a, b) => (spentBy[b.id] ?? 0).compareTo(spentBy[a.id] ?? 0));
    final shown = rows.take(5).toList();
    const faint = Color(0x2EFFFFFF);
    const soft = Color(0xFFFFB4AB);

    Widget hero;
    if (budget > 0) {
      final left = budget - total;
      final over = left < 0;
      hero = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          DonutChart(
            size: 130,
            semanticLabel: 'Spent ${rupees(total)} of ${rupees(budget)} budget',
            track: faint,
            segments: [
              DonutSeg(math.min(total, budget), over ? soft : C.mint),
              DonutSeg(math.max(0.0, budget - total), faint),
            ],
            center: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(rupees(budget), style: serif(17, color: Colors.white)),
              Text('Total budget', style: sans(11, color: C.lightGreen)),
            ]),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Spent', style: sans(14, color: C.lightGreen)),
              Text(rupees(total), style: serif(30, color: Colors.white)),
              const SizedBox(height: 10),
              Text(over ? 'Over budget' : 'Remaining', style: sans(14, color: C.lightGreen)),
              Text(rupees(left.abs()), style: serif(30, color: over ? soft : C.mint)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Text('${(total / budget * 100).round()}% of ${kMonths[now.month - 1]} budget used',
            style: sans(14, color: Colors.white)),
      ]);
    } else {
      hero = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${kMonths[now.month - 1]} spend', style: sans(14, color: C.lightGreen)),
        Text(rupees(total), style: serif(48, color: Colors.white)),
        const SizedBox(height: 4),
        Text('No monthly budget yet. Add limits to get alerts.',
            style: sans(15, color: C.lightGreen)),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const BudgetsScreen())),
          style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: Text('Set monthly budget', style: sans(16, w: FontWeight.w700)),
        ),
      ]);
    }

    return ListView(padding: EdgeInsets.zero, children: [
      ForestBlock(child: hero),
      Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Category summary', style: serif(24)),
            TextButton(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const CategoriesScreen())),
              child: Text('View all', style: sans(14, w: FontWeight.w700, color: C.forest)),
            ),
          ]),
          const SizedBox(height: 12),
          if (shown.isEmpty)
            Text('No expenses yet. Tap + to add your first one.',
                style: sans(16, color: C.text2))
          else
            GreyCard(
              child: Column(children: [
                for (var i = 0; i < shown.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == shown.length - 1 ? 0 : 16),
                    child: CategoryProgressRow(
                      name: shown[i].name,
                      spent: spentBy[shown[i].id] ?? 0,
                      limit: shown[i].limit,
                    ),
                  ),
              ]),
            ),
        ]),
      ),
    ]);
  }
}

// --------------------------------------------------------------- History

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});
  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  DateTime _month = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final list = s.expensesIn(_month).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ListView(padding: const EdgeInsets.all(24), children: [
      Text('Transactions', style: serif(30)),
      const SizedBox(height: 12),
      MonthPicker(month: _month, earliest: s.earliest, onChanged: (m) => setState(() => _month = m)),
      const SizedBox(height: 16),
      if (list.isEmpty)
        Text('No expenses in ${monthLabel(_month)}.', style: sans(16, color: C.text2)),
      for (final e in list)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GreyCard(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Initial(e.payee.isEmpty ? s.catName(e.categoryId) : e.payee),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.payee.isEmpty ? s.catName(e.categoryId) : e.payee,
                      style: sans(15, w: FontWeight.w700)),
                  Text(s.catName(e.categoryId), style: sans(13, color: C.text2)),
                  Text('${dateLabel(e.createdAt)}, ${timeLabel(e.createdAt)} · ${e.method}',
                      style: sans(13, color: C.text2)),
                  if (e.note.isNotEmpty) Text(e.note, style: sans(13, color: C.text2)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(rupees(e.amount), style: sans(16, w: FontWeight.w700)),
                if (e.status == kFailed)
                  Text('Failed', style: sans(13, w: FontWeight.w700, color: C.danger)),
                if (e.status == kPending)
                  TextButton(
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, minimumSize: const Size(48, 44)),
                    onPressed: () async {
                      final alerts = await s.setStatus(e.id, kConfirmed);
                      toast(alerts.isNotEmpty ? alerts.join('\n') : 'Marked as paid.');
                    },
                    child: Text('Pending: mark paid',
                        style: sans(13, w: FontWeight.w700, color: C.forest)),
                  ),
              ]),
            ]),
          ),
        ),
    ]);
  }
}

// --------------------------------------------------------------- Reports

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});
  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  DateTime _month = DateTime.now();
  static const palette = [
    C.mint, C.forest, Color(0xFF111111), C.lightGreen, Color(0xFFE8A317), C.forestMid
  ];

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final by = s.byCategoryIn(_month);
    final total = s.totalIn(_month);
    final entries = by.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return ListView(padding: const EdgeInsets.all(24), children: [
      Text('Reports', style: serif(30)),
      const SizedBox(height: 12),
      MonthPicker(month: _month, earliest: s.earliest, onChanged: (m) => setState(() => _month = m)),
      const SizedBox(height: 16),
      if (entries.isEmpty)
        Text('No expenses in ${monthLabel(_month)}.', style: sans(16, color: C.text2))
      else ...[
        Center(
          child: DonutChart(
            size: 190,
            semanticLabel: 'Spending by category, total ${rupees(total)}',
            segments: [
              for (var i = 0; i < entries.length; i++)
                DonutSeg(entries[i].value, palette[i % palette.length]),
            ],
            center: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(rupees(total), style: serif(22)),
              Text('Spent', style: sans(12, color: C.text2)),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        GreyCard(
          child: Column(children: [
            for (var i = 0; i < entries.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == entries.length - 1 ? 0 : 12),
                child: Row(children: [
                  Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                          color: palette[i % palette.length], shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s.catName(entries[i].key), style: sans(15))),
                  Text(rupees(entries[i].value), style: sans(15, w: FontWeight.w700)),
                  SizedBox(
                    width: 48,
                    child: Text('${(entries[i].value / total * 100).round()}%',
                        textAlign: TextAlign.end, style: sans(14, color: C.text2)),
                  ),
                ]),
              ),
          ]),
        ),
      ],
    ]);
  }
}

// --------------------------------------------------------------- Profile

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    Widget item(String label, VoidCallback onTap) => InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 54),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFDADADA)))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(label, style: sans(16)),
              const ExcludeSemantics(child: Icon(Icons.chevron_right, color: C.text2)),
            ]),
          ),
        );
    void open(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

    return ListView(padding: EdgeInsets.zero, children: [
      ForestBlock(
        child: Row(children: [
          Initial(s.displayName, size: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.fullName.isEmpty ? 'Your account' : s.fullName,
                  style: serif(26, color: Colors.white)),
              Text(s.formattedMobile, style: sans(14, color: C.lightGreen)),
            ]),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GreyCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              item('Categories and budgets', () => open(const CategoriesScreen())),
              item('Notifications', () => open(const NotificationsScreen())),
              item('Appearance', () => open(const AppearanceScreen())),
              item(
                  'Security & privacy',
                  () => open(const InfoScreen(
                      title: 'Security & privacy',
                      body:
                          'Your data is stored on this device for now. Account protection and data controls will be added when cloud accounts are connected.'))),
              item(
                  'Help & support',
                  () => open(const InfoScreen(
                      title: 'Help & support',
                      body: 'Help and support contact details will be added before launch.'))),
              item(
                  'About the app',
                  () => open(const InfoScreen(
                      title: 'About the app', body: 'Expense Tracker\nVersion 1.0.0'))),
            ]),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: s.logout,
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: Text('Log out', style: sans(16, w: FontWeight.w700)),
          ),
          const SizedBox(height: 20),
          Text('Your data is saved in this browser only for now.',
              style: sans(14, color: C.text2)),
        ]),
      ),
    ]);
  }
}
