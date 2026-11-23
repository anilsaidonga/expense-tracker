import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

Widget _page(Widget child) => Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        const TopBar(),
        Expanded(child: child),
      ]),
    );

/// "View all": every category with its limit, and Edit / Add.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final spent = s.byCategoryIn(DateTime.now());
    return _page(ListView(padding: const EdgeInsets.all(24), children: [
      const BackLink(),
      Semantics(header: true, child: Text('Categories and limits', style: serif(30))),
      const SizedBox(height: 6),
      Text('Tap Edit to change a name, a limit or its alerts.', style: sans(15, color: C.text2)),
      const SizedBox(height: 16),
      GreyCard(
        child: Column(children: [
          for (var i = 0; i < s.categories.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == s.categories.length - 1 ? 0 : 16),
              child: CategoryProgressRow(
                name: s.categories[i].name,
                spent: spent[s.categories[i].id] ?? 0,
                limit: s.categories[i].limit,
                trailing: Semantics(
                  label: 'Edit ${s.categories[i].name}',
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => EditCategoryScreen(category: s.categories[i]))),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black, width: 2),
                        minimumSize: const Size(64, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22))),
                    child: Text('Edit', style: sans(13, w: FontWeight.w700)),
                  ),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 16),
      AppButton('+ Add category',
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const EditCategoryScreen()))),
    ]));
  }
}

/// Add a new category, or edit an existing one (name, limit, alerts).
class EditCategoryScreen extends StatefulWidget {
  const EditCategoryScreen({super.key, this.category});
  final Category? category;
  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  late final TextEditingController _name;
  late final TextEditingController _limit;
  late bool _notify;
  int? _level;
  bool? _cross;
  bool _init = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _name = TextEditingController(text: c?.name ?? '');
    _limit = TextEditingController(text: c?.limit == null ? '' : c!.limit!.round().toString());
    _notify = c?.notify ?? true;
    _level = c?.alertAt;
    _cross = c?.alertOnCross;
  }

  @override
  void dispose() {
    _name.dispose();
    _limit.dispose();
    super.dispose();
  }

  Future<void> _save(AppState s) async {
    if (_saving) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final name = _name.text.trim();
    if (name.isEmpty) {
      toast('Enter a category name.');
      return;
    }
    final clash = s.categories.any((c) =>
        c.id != widget.category?.id && c.name.toLowerCase() == name.toLowerCase());
    if (clash) {
      toast('A category named "$name" already exists.');
      return;
    }
    double? limit;
    if (_limit.text.trim().isNotEmpty) {
      limit = parseMoney(_limit.text);
      if (limit == null || limit <= 0) {
        toast('Enter a limit greater than zero, or leave it empty.');
        return;
      }
    }
    // Store a level only when it differs from the default.
    final level = (_level == null || _level == s.defaultAlertAt) ? null : _level;
    final cross = (_cross == null || _cross == s.defaultCross) ? null : _cross;
    final nav = Navigator.of(context);
    setState(() => _saving = true);
    try {
      if (widget.category == null) {
        await s.addCategory(name, limit: limit, notify: _notify, alertAt: level, cross: cross);
      } else {
        await s.updateCategory(widget.category!.id,
            name: name, limit: limit, notify: _notify, alertAt: level, cross: cross);
      }
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      toast('Could not save: $e');
      return;
    }
    nav.pop();
    toast('Saved.');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    if (!_init) {
      _init = true;
      _level ??= s.defaultAlertAt;
      _cross ??= s.defaultCross;
    }
    final existing = widget.category;
    final canDelete = existing != null && existing.id != kOtherId;
    final lim = parseMoney(_limit.text);
    final limV = (lim != null && lim > 0) ? lim : null;
    final level = _level ?? s.defaultAlertAt;

    return _page(ListView(padding: const EdgeInsets.all(24), children: [
      const BackLink(),
      Semantics(
          header: true,
          child: Text(existing == null ? 'New category' : 'Edit category', style: serif(30))),
      const SizedBox(height: 20),
      const SectionLabel('Details'),
      GreyCard(
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          AppField(label: 'Name', controller: _name, onCard: true),
          const SizedBox(height: 12),
          AppField(
              label: 'Monthly limit (₹)',
              controller: _limit,
              onCard: true,
              keyboard: TextInputType.number,
              hint: 'Leave empty for no limit',
              onChanged: (_) => setState(() {})),
        ]),
      ),
      const SizedBox(height: 20),
      const SectionLabel('Alerts'),
      SectionCard(rows: [
        SettingRow(
          title: 'Notify me about this category',
          sub: 'Get alerts as you spend',
          trailing: Switch(value: _notify, onChanged: (v) => setState(() => _notify = v)),
        ),
        if (_notify)
          LevelSlider(
            label: 'Alert when spending reaches',
            value: level,
            onChanged: (v) => setState(() => _level = v),
            helper: limV != null
                ? "You'll be alerted at ${rupees(limV * level / 100)} of ${rupees(limV)}."
                : 'Set a monthly limit to see the alert amount.',
          ),
        SettingRow(
          title: 'Also alert when the limit is crossed',
          sub: limV != null ? 'At ${rupees(limV)}' : null,
          trailing: Switch(
              value: _cross ?? true, onChanged: (v) => setState(() => _cross = v)),
        ),
      ]),
      const SizedBox(height: 24),
      AppButton(_saving ? 'Saving...' : 'Save changes',
          onPressed: _saving ? null : () => _save(s)),
      if (canDelete) ...[
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () async {
              final nav = Navigator.of(context);
              final ok = await askYesNo(context, 'Delete "${existing.name}"?',
                  'Its expenses will move to Others.', 'Delete');
              if (ok) {
                await s.deleteCategory(existing.id);
                nav.pop();
              }
            },
            child: Text('Delete category', style: sans(15, w: FontWeight.w700, color: C.danger)),
          ),
        ),
        Center(child: Text('Its expenses move to Others.', style: sans(13, color: C.text2))),
      ],
    ]));
  }
}

/// "Set monthly budget": one limit per category plus a live total.
/// With onboarding: true it is sign-up step 4 and can be skipped.
class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key, this.onboarding = false});
  final bool onboarding;
  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final _c = <String, TextEditingController>{};

  TextEditingController _ctrl(Category c) => _c.putIfAbsent(
      c.id, () => TextEditingController(text: c.limit == null ? '' : c.limit!.round().toString()));

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _total => _c.values.fold(0.0, (a, c) => a + (parseMoney(c.text) ?? 0));

  Future<void> _save(AppState s) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final map = <String, double?>{};
    for (final c in s.categories) {
      final t = _ctrl(c).text.trim();
      if (t.isEmpty) {
        map[c.id] = null;
      } else {
        final v = parseMoney(t);
        if (v == null || v <= 0) {
          toast('Check the limit for ${c.name}.');
          return;
        }
        map[c.id] = v;
      }
    }
    final nav = Navigator.of(context);
    try {
      await s.setLimits(map);
    } catch (e) {
      toast('Could not save: $e');
      return;
    }
    if (!mounted) return;
    if (widget.onboarding) {
      await finishOnboarding(context);
    } else {
      nav.pop();
      toast('Budget saved.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    for (final c in s.categories) {
      _ctrl(c);
    }
    final ob = widget.onboarding;
    return _page(ListView(padding: const EdgeInsets.all(24), children: [
      if (ob) ...[const StepDots(4), const SizedBox(height: 20)] else const BackLink(),
      Semantics(
          header: true,
          child: Text(ob ? 'Set your monthly budget' : 'Monthly budget', style: serif(30))),
      const SizedBox(height: 6),
      Text(
          ob
              ? 'Add or change categories. You can edit these later.'
              : 'Set a limit for each category. Leave empty for no limit.',
          style: sans(15, color: C.text2)),
      const SizedBox(height: 16),
      GreyCard(
        child: Column(children: [
          for (final c in s.categories)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Initial(c.name, size: 36),
                const SizedBox(width: 10),
                Expanded(child: Text(c.name, style: sans(15, w: FontWeight.w700))),
                MoneyBox(
                    label: '${c.name} monthly limit',
                    controller: _ctrl(c),
                    onChanged: (_) => setState(() {})),
              ]),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () async {
                final n = await askText(context, 'New category');
                if (n != null && n.isNotEmpty) {
                  await s.addCategory(n);
                  setState(() {});
                }
              },
              child: Text('+ Add category', style: sans(14, w: FontWeight.w700, color: C.forest)),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      ForestBlock(
        radius: 20,
        padding: const EdgeInsets.all(16),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total monthly budget', style: sans(14, color: C.lightGreen)),
          Text(rupees(_total), style: serif(28, color: Colors.white)),
        ]),
      ),
      const SizedBox(height: 16),
      AppButton(ob ? 'Save and continue' : 'Save budget', onPressed: () => _save(s)),
      if (ob) ...[
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => finishOnboarding(context),
            child: Text('Skip for now', style: sans(16, w: FontWeight.w700, color: C.forest)),
          ),
        ),
      ],
    ]));
  }
}
