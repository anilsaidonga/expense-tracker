import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_state.dart';
import 'models.dart';
import 'theme.dart';

final messengerKey = GlobalKey<ScaffoldMessengerState>();

/// Short message at the bottom. SnackBars are announced by screen readers.
void toast(String message) {
  messengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message, style: sans(15, color: Colors.white)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.black,
      duration: const Duration(seconds: 5),
    ));
}

Future<String?> askText(BuildContext context, String title, {String initial = ''}) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Name'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
      ],
    ),
  );
}

Future<bool> askYesNo(BuildContext context, String title, String body, String yes) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(yes)),
      ],
    ),
  );
  return r ?? false;
}

double? parseMoney(String s) => double.tryParse(s.replaceAll(',', '').replaceAll('₹', '').trim());

const _hint = Color(0xFF6B6B6B); // readable on white and on the grey cards

// ---------------------------------------------------------------- layout

class TopBar extends StatelessWidget {
  const TopBar({super.key, this.onBell});
  final VoidCallback? onBell;
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      color: C.mint,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(children: [
        ExcludeSemantics(
          child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(appName, style: sans(22, w: FontWeight.w700)),
          ),
        ),
        if (onBell != null)
          IconButton(
            tooltip: 'Alerts',
            onPressed: onBell,
            icon: const Icon(Icons.notifications_none, size: 28, color: Colors.black),
          ),
      ]),
    );
  }
}

class ForestBlock extends StatelessWidget {
  const ForestBlock(
      {super.key, required this.child, this.padding = const EdgeInsets.all(24), this.radius = 0});
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  Widget _circle(double d, Color c) => ExcludeSemantics(
      child: Container(width: d, height: d, decoration: BoxDecoration(color: c, shape: BoxShape.circle)));

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: ColoredBox(
          color: C.forest,
          child: Stack(children: [
            Positioned(right: -90, top: -70, child: _circle(300, C.forestMid)),
            Positioned(left: -70, bottom: -110, child: _circle(240, C.forestDark)),
            Padding(padding: padding, child: child),
          ]),
        ),
      ),
    );
  }
}

class GreyCard extends StatelessWidget {
  const GreyCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(color: C.grey, borderRadius: BorderRadius.circular(20)),
        child: child,
      );
}

enum BtnKind { dark, light, outline, outlineDark }

class AppButton extends StatelessWidget {
  const AppButton(this.label, {super.key, required this.onPressed, this.kind = BtnKind.dark});
  final String label;
  final VoidCallback? onPressed;
  final BtnKind kind;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    final text = GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700);
    const min = Size.fromHeight(56); // grows with larger text sizes
    final outlined = kind == BtnKind.outline || kind == BtnKind.outlineDark;
    final lineColor = kind == BtnKind.outline ? Colors.white : Colors.black;
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                  minimumSize: min,
                  foregroundColor: lineColor,
                  side: BorderSide(color: lineColor, width: 2),
                  shape: shape),
              child: Text(label, style: text))
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                  minimumSize: min,
                  backgroundColor: kind == BtnKind.dark ? Colors.black : Colors.white,
                  foregroundColor: kind == BtnKind.dark ? Colors.white : Colors.black,
                  shape: shape),
              child: Text(label, style: text)),
    );
  }
}

class AppField extends StatelessWidget {
  const AppField({
    super.key,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.onDark = false,
    this.onCard = false,
    this.keyboard,
    this.hint,
    this.onChanged,
  });
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final bool onDark;
  final bool onCard;
  final TextInputType? keyboard;
  final String? hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ExcludeSemantics(
          child: Text(label, style: sans(14, color: onDark ? Colors.white : C.text2))),
      const SizedBox(height: 8),
      Semantics(
        label: label,
        textField: true,
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          onChanged: onChanged,
          style: sans(16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: sans(16, color: _hint),
            filled: true,
            fillColor: (onDark || onCard) ? Colors.white : C.grey,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ),
    ]);
  }
}

/// Small money box used in the budget list.
class MoneyBox extends StatelessWidget {
  const MoneyBox({super.key, required this.label, required this.controller, this.onChanged});
  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Semantics(
        label: label,
        textField: true,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.end,
          onChanged: onChanged,
          style: sans(16, w: FontWeight.w700),
          decoration: InputDecoration(
            isDense: true,
            hintText: '₹0',
            hintStyle: sans(16, color: _hint),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ),
    );
  }
}

/// Tappable box that looks like a field (used for date and time).
class PickerField extends StatelessWidget {
  const PickerField({super.key, required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ExcludeSemantics(child: Text(label, style: sans(14, color: C.text2))),
      const SizedBox(height: 8),
      Semantics(
        button: true,
        label: '$label, $value',
        excludeSemantics: true,
        onTap: onTap,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(color: C.grey, borderRadius: BorderRadius.circular(16)),
            child: Text(value, style: sans(16)),
          ),
        ),
      ),
    ]);
  }
}

class Initial extends StatelessWidget {
  const Initial(this.name, {super.key, this.size = 40});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(color: C.tint, shape: BoxShape.circle),
          child: Center(
            child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                style: sans(size / 2.6, w: FontWeight.w700, color: C.forest)),
          ),
        ),
      );
}

/// The one back control used on every drill-down screen.
class BackLink extends StatelessWidget {
  const BackLink({super.key, this.color = Colors.black});
  final Color color;
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.arrow_back, size: 20, color: color),
          label: Text('Back', style: sans(16, w: FontWeight.w700, color: color)),
          style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.only(right: 12),
              foregroundColor: color),
        ),
      );
}

class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.current, required this.onTap});
  final int current;
  final ValueChanged<int> onTap;
  static const labels = ['Home', 'History', 'Add', 'Reports', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(5, (i) {
          if (i == 2) {
            return SizedBox(
              width: 72,
              height: 48,
              child: Tooltip(
                message: 'Add an expense',
                child: FilledButton(
                  onPressed: () => onTap(2),
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                  child: const Icon(Icons.add, size: 28, semanticLabel: 'Add an expense'),
                ),
              ),
            );
          }
          final active = current == i;
          return Expanded(
            child: Semantics(
              selected: active,
              child: TextButton(
                onPressed: () => onTap(i),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: Text(labels[i],
                    style: sans(13,
                        w: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? C.mint : Colors.white)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.label,
      {super.key, required this.onTap, this.selected = false, this.dashed = false});
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool dashed;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.black : (dashed ? Colors.white : C.grey),
            borderRadius: BorderRadius.circular(22),
            border: dashed ? Border.all(color: C.forest, width: 2) : null,
          ),
          child: Text(label,
              style: sans(13,
                  w: FontWeight.w700,
                  color: selected ? Colors.white : (dashed ? C.forest : Colors.black))),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- charts

class DonutSeg {
  final double value;
  final Color color;
  const DonutSeg(this.value, this.color);
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.segs, this.track, this.stroke);
  final List<DonutSeg> segs;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, 2 * math.pi, false, base..color = track);
    final total = segs.fold(0.0, (a, s) => a + s.value);
    if (total <= 0) return;
    var start = -math.pi / 2;
    for (final s in segs) {
      final sweep = s.value / total * 2 * math.pi;
      if (sweep > 0.02) {
        canvas.drawArc(rect, start, sweep - 0.02, false, base..color = s.color);
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}

class DonutChart extends StatelessWidget {
  const DonutChart(
      {super.key,
      required this.segments,
      required this.center,
      this.semanticLabel = 'Chart',
      this.size = 140,
      this.stroke = 14,
      this.track = const Color(0xFFE4E4E4)});
  final List<DonutSeg> segments;
  final Widget center;
  final String semanticLabel;
  final double size;
  final double stroke;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DonutPainter(segments, track, stroke),
            child: Center(child: center),
          ),
        ),
      ),
    );
  }
}

/// Progress bar. The numbers next to it say the same thing, so it is hidden from screen readers.
class LimitBar extends StatelessWidget {
  const LimitBar(this.ratio, {super.key});
  final double ratio;
  @override
  Widget build(BuildContext context) {
    final color = ratio > 1 ? C.danger : (ratio > 0.8 ? const Color(0xFFE8A317) : C.mint);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: ratio.clamp(0.0, 1.0).toDouble(),
          minHeight: 6,
          backgroundColor: const Color(0xFFDADADA),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

class CategoryProgressRow extends StatelessWidget {
  const CategoryProgressRow(
      {super.key, required this.name, required this.spent, this.limit, this.trailing});
  final String name;
  final double spent;
  final double? limit;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final lim = limit ?? 0;
    final has = lim > 0;
    return Row(children: [
      Initial(name),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(
                child: Text(name,
                    overflow: TextOverflow.ellipsis, style: sans(15, w: FontWeight.w700))),
            const SizedBox(width: 8),
            Text(has ? '${rupees(spent)} / ${rupees(lim)}' : rupees(spent),
                style: sans(14, w: FontWeight.w700)),
          ]),
          const SizedBox(height: 6),
          if (has) ...[
            LimitBar(spent / lim),
            const SizedBox(height: 4),
            spent > lim
                ? Text('Over by ${rupees(spent - lim)}',
                    style: sans(12, w: FontWeight.w700, color: C.danger))
                : Text('${rupees(lim - spent)} left', style: sans(12, color: C.text2)),
          ] else
            Text('No limit set', style: sans(12, color: C.text2)),
        ]),
      ),
      if (trailing != null) ...[const SizedBox(width: 10), trailing!],
    ]);
  }
}

// ---------------------------------------------------------------- pickers

class MonthPicker extends StatelessWidget {
  const MonthPicker({super.key, required this.month, required this.onChanged, this.earliest});
  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  final DateTime? earliest;

  bool get _atNow => sameMonth(month, DateTime.now());

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final start = earliest ?? DateTime(now.year, now.month - 11);
    final first = DateTime(start.year, start.month);
    final months = <DateTime>[];
    var m = DateTime(now.year, now.month);
    while (!m.isBefore(first)) {
      months.add(m);
      m = DateTime(m.year, m.month - 1);
    }
    final r = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          for (final x in months)
            ListTile(
              title: Text(monthLabel(x), style: sans(16, w: FontWeight.w500)),
              selected: sameMonth(x, month),
              onTap: () => Navigator.pop(ctx, x),
            ),
        ]),
      ),
    );
    if (r != null) onChanged(r);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: C.grey, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        IconButton(
          tooltip: 'Previous month',
          onPressed: () => onChanged(DateTime(month.year, month.month - 1)),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: TextButton(
            onPressed: () => _pick(context),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text('${monthLabel(month)} ▾', style: sans(16, w: FontWeight.w700)),
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          onPressed: _atNow ? null : () => onChanged(DateTime(month.year, month.month + 1)),
          icon: const Icon(Icons.chevron_right),
        ),
      ]),
    );
  }
}

/// Shows 3 categories (last used for this payee, then most used) plus "More".
class CategoryChooser extends StatelessWidget {
  const CategoryChooser(
      {super.key,
      required this.state,
      required this.selectedId,
      required this.onSelected,
      this.suggestedId});
  final AppState state;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final String? suggestedId;

  @override
  Widget build(BuildContext context) {
    final spent = state.byCategoryIn(DateTime.now());
    final sorted = [...state.categories]
      ..sort((a, b) => (spent[b.id] ?? 0).compareTo(spent[a.id] ?? 0));
    final ids = <String>[];
    void add(String? id) {
      if (id != null && !ids.contains(id) && state.catById(id) != null) ids.add(id);
    }

    add(suggestedId);
    for (final c in sorted) {
      add(c.id);
    }
    var shown = ids.take(3).toList();
    if (!shown.contains(selectedId)) {
      shown = shown.length < 3 ? [...shown, selectedId] : [shown[0], shown[1], selectedId];
    }
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final id in shown)
        Pill(state.catName(id), selected: id == selectedId, onTap: () => onSelected(id)),
      Pill('More ▸', dashed: true, onTap: () async {
        final c = await showCategoryPicker(context, state);
        if (c != null) onSelected(c.id);
      }),
    ]);
  }
}

Future<Category?> showCategoryPicker(BuildContext context, AppState s) {
  return showModalBottomSheet<Category>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => _CategoryPicker(state: s),
  );
}

class _CategoryPicker extends StatefulWidget {
  const _CategoryPicker({required this.state});
  final AppState state;
  @override
  State<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<_CategoryPicker> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.text.trim();
    final ql = q.toLowerCase();
    final list =
        widget.state.categories.where((c) => c.name.toLowerCase().contains(ql)).toList();
    final exact = widget.state.categories.any((c) => c.name.toLowerCase() == ql);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Semantics(header: true, child: Text('Choose category', style: serif(26))),
            const SizedBox(height: 12),
            AppField(label: 'Search', controller: _q, onChanged: (_) => setState(() {})),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(shrinkWrap: true, children: [
                for (final c in list)
                  ListTile(
                    leading: Initial(c.name, size: 36),
                    title: Text(c.name, style: sans(15, w: FontWeight.w700)),
                    onTap: () => Navigator.pop(context, c),
                  ),
                if (q.isNotEmpty && !exact)
                  ListTile(
                    leading: const Icon(Icons.add, color: C.forest),
                    title: Text('Create "$q" as a new category',
                        style: sans(15, w: FontWeight.w700, color: C.forest)),
                    onTap: () async {
                      final c = await widget.state.addCategory(q);
                      if (context.mounted) Navigator.pop(context, c);
                    },
                  ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ------------------------------------------------------ settings widgets

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Semantics(header: true, child: Text(text, style: sans(13, color: C.text2))),
      );
}

/// A grey card whose rows are separated by thin dividers.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.rows});
  final List<Widget> rows;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: C.grey, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Divider(height: 1, thickness: 1, color: Color(0xFFDADADA)),
          Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: rows[i]),
        ],
      ]),
    );
  }
}

/// Title, optional grey line and a trailing control. A plain Switch gets the title as its label.
class SettingRow extends StatelessWidget {
  const SettingRow({super.key, required this.title, this.sub, this.trailing});
  final String title;
  final String? sub;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final isSwitch = trailing is Switch;
    final text = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: sans(15)),
      if (sub != null) Text(sub!, style: sans(13, color: C.text2)),
    ]);
    return Row(children: [
      Expanded(child: isSwitch ? ExcludeSemantics(child: text) : text),
      if (trailing != null)
        isSwitch
            ? Semantics(label: sub == null ? title : '$title. $sub', child: trailing)
            : trailing!,
    ]);
  }
}

/// Slider (10 to 100, steps of 5) plus a box where any whole number can be typed.
class LevelSlider extends StatefulWidget {
  const LevelSlider(
      {super.key, required this.label, required this.value, required this.onChanged, this.helper});
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final String? helper;
  @override
  State<LevelSlider> createState() => _LevelSliderState();
}

class _LevelSliderState extends State<LevelSlider> {
  late final TextEditingController _c = TextEditingController(text: '${widget.value}');
  final _f = FocusNode();

  @override
  void dispose() {
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LevelSlider old) {
    super.didUpdateWidget(old);
    if (!_f.hasFocus && _c.text != '${widget.value}') _c.text = '${widget.value}';
  }

  /// Valid numbers are applied while typing, so Save always sees the latest value.
  void _typing(String t) {
    final v = int.tryParse(t.trim());
    if (v != null && v >= 10 && v <= 100) widget.onChanged(v);
  }

  void _commit() {
    final v = int.tryParse(_c.text.trim());
    final r = (v ?? widget.value).clamp(10, 100).toInt();
    _c.text = '$r';
    if (r != widget.value) widget.onChanged(r);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: ExcludeSemantics(child: Text(widget.label, style: sans(15)))),
        SizedBox(
          width: 84,
          child: Focus(
            onFocusChange: (has) {
              if (!has && mounted) _commit();
            },
            child: Semantics(
              label: '${widget.label}, percent',
              textField: true,
              child: TextField(
                controller: _c,
                focusNode: _f,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.end,
                onChanged: _typing,
                onSubmitted: (_) => _commit(),
                style: sans(16, w: FontWeight.w700),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  suffixText: '%',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black, width: 2)),
                ),
              ),
            ),
          ),
        ),
      ]),
      Semantics(
        label: widget.label,
        child: Slider(
          value: widget.value.clamp(10, 100).toDouble(),
          min: 10,
          max: 100,
          divisions: 18,
          label: '${widget.value}%',
          semanticFormatterCallback: (v) => '${v.round()} percent',
          onChanged: (v) => widget.onChanged(v.round()),
        ),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('10%', style: sans(12, color: C.text2)),
        Text('100%', style: sans(12, color: C.text2)),
      ]),
      if (widget.helper != null) ...[
        const SizedBox(height: 6),
        Text(widget.helper!, style: sans(13, w: FontWeight.w700, color: C.forest)),
      ],
    ]);
  }
}

// ------------------------------------------------------------ onboarding

class StepDots extends StatelessWidget {
  const StepDots(this.step, {super.key, this.total = 4});
  final int step;
  final int total;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step $step of $total',
      excludeSemantics: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          for (var i = 0; i < total; i++)
            Container(
              width: 44,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                  color: i < step ? C.forest : const Color(0xFFDADADA),
                  borderRadius: BorderRadius.circular(3)),
            ),
        ]),
        const SizedBox(height: 8),
        Text('Step $step of $total', style: sans(13, color: C.text2)),
      ]),
    );
  }
}

/// Last step of sign-up (or its skip): signs the user in and shows Home.
Future<void> finishOnboarding(BuildContext context) async {
  final s = AppScope.of(context);
  final nav = Navigator.of(context);
  await s.signIn();
  nav.popUntil((r) => r.isFirst);
  toast('Welcome! Tap + to add your first expense.');
}
