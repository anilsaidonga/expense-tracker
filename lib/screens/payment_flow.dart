import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

Widget _page(Widget child, {Color bg = Colors.white}) => Scaffold(
      backgroundColor: bg,
      body: Column(children: [
        const TopBar(),
        Expanded(child: child),
      ]),
    );

/// Big centred amount box used on the Pay and Add manually screens.
Widget _amountBox(TextEditingController c, String caption) => GreyCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(children: [
        ExcludeSemantics(child: Text(caption, style: sans(13, color: C.text2))),
        Semantics(
          label: 'Amount in rupees. $caption',
          textField: true,
          child: TextField(
            controller: c,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: serif(48),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '0',
              hintStyle: serif(48, color: const Color(0xFF8A8A8A)),
              prefixText: '₹',
              prefixStyle: serif(48),
            ),
          ),
        ),
      ]),
    );

// ---------------------------------------------------------------- Scan

/// Web build: paste a UPI link or ID instead of using the camera.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _go(Draft d) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => PayScreen(draft: d)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.white, foregroundColor: Colors.black),
                child: Text('Close', style: sans(14, w: FontWeight.w700)),
              ),
              Text('Scan to pay', style: sans(17, w: FontWeight.w700, color: Colors.white)),
              const SizedBox(width: 76),
            ]),
            const SizedBox(height: 56),
            SizedBox(width: 260, height: 260, child: CustomPaint(painter: _FramePainter())),
            const SizedBox(height: 24),
            Text('Camera scanning comes with the mobile app.\nOn web, paste a UPI link or UPI ID.',
                textAlign: TextAlign.center, style: sans(16, color: Colors.white)),
            const SizedBox(height: 24),
            AppField(
              label: 'UPI link or UPI ID',
              controller: _ctrl,
              onDark: true,
              hint: 'upi://pay?pa=name@bank&pn=Shop   or   name@bank',
            ),
            const SizedBox(height: 16),
            AppButton('Continue', kind: BtnKind.light, onPressed: () => _go(parseUpi(_ctrl.text))),
            const SizedBox(height: 12),
            AppButton('Enter details manually',
                kind: BtnKind.outline, onPressed: () => _go(const Draft())),
          ]),
        ),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = C.mint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const l = 44.0, r = 22.0;
    final w = s.width, h = s.height;
    const rad = Radius.circular(r);
    final path = Path()
      ..moveTo(0, l)
      ..lineTo(0, r)
      ..arcToPoint(const Offset(r, 0), radius: rad)
      ..lineTo(l, 0)
      ..moveTo(w - l, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: rad)
      ..lineTo(w, l)
      ..moveTo(w, h - l)
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: rad)
      ..lineTo(w - l, h)
      ..moveTo(l, h)
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: rad)
      ..lineTo(0, h - l);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------------------- Pay

/// After scanning: amount, category and UPI app on ONE screen.
class PayScreen extends StatefulWidget {
  const PayScreen({super.key, required this.draft});
  final Draft draft;
  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  static const apps = ['Google Pay', 'PhonePe', 'Paytm', 'BHIM UPI', 'Amazon Pay', 'Other UPI app'];
  late final TextEditingController _payee;
  late final TextEditingController _amount;
  String? _catId;
  String _app = apps.first;

  @override
  void initState() {
    super.initState();
    _payee = TextEditingController(text: widget.draft.payee);
    final a = widget.draft.amount;
    _amount = TextEditingController(
        text: a == null ? '' : (a == a.roundToDouble() ? a.round().toString() : a.toString()));
  }

  @override
  void dispose() {
    _payee.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _moreApps() async {
    final r = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(24), children: [
          Text('Choose UPI app', style: serif(26)),
          const SizedBox(height: 12),
          for (final a in apps)
            ListTile(
              title: Text(a, style: sans(16, w: FontWeight.w700)),
              trailing: a == _app ? const Icon(Icons.check, color: C.forest) : null,
              onTap: () => Navigator.pop(ctx, a),
            ),
        ]),
      ),
    );
    if (r != null) setState(() => _app = r);
  }

  void _continue(AppState s) {
    final amount = parseMoney(_amount.text);
    if (amount == null || amount <= 0) {
      toast('Enter the amount you are paying.');
      return;
    }
    final e = Expense(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      amount: amount,
      categoryId: _catId ?? s.categories.first.id,
      payee: _payee.text.trim(),
      upiId: widget.draft.upiId,
      upiApp: _app,
      method: 'UPI',
      note: '',
      status: kPending,
      createdAt: DateTime.now(), // time the payment was started
    );
    // On mobile, launch the UPI app here (url_launcher / a UPI package) first.
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProcessingScreen(expense: e)));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final suggested = s.payeeCategory[_payee.text.trim()];
    _catId ??= suggested ?? s.categories.first.id;
    final cat = s.catById(_catId!);
    final lim = cat?.limit ?? 0;
    final left = lim - s.spentIn(_catId!, DateTime.now());
    final visibleApps = apps.take(2).toList();
    if (!visibleApps.contains(_app)) visibleApps.add(_app);

    return _page(ListView(padding: const EdgeInsets.all(24), children: [
      const BackLink(),
      Center(
        child: Column(children: [
          Initial(_payee.text.isEmpty ? '?' : _payee.text, size: 56),
          const SizedBox(height: 8),
          SizedBox(
            width: 260,
            child: TextField(
              controller: _payee,
              textAlign: TextAlign.center,
              onChanged: (_) => setState(() {}),
              style: sans(18, w: FontWeight.w700),
              decoration: const InputDecoration(
                  border: InputBorder.none, hintText: 'Paid to (shop or person)'),
            ),
          ),
          if (widget.draft.upiId.isNotEmpty)
            Text(widget.draft.upiId, style: sans(14, color: C.text2)),
        ]),
      ),
      const SizedBox(height: 12),
      _amountBox(_amount, 'Enter the amount you are paying'),
      const SizedBox(height: 16),
      Text('Category', style: sans(14, w: FontWeight.w700, color: C.text2)),
      const SizedBox(height: 8),
      CategoryChooser(
          state: s,
          selectedId: _catId!,
          suggestedId: suggested,
          onSelected: (id) => setState(() => _catId = id)),
      if (lim > 0) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration:
              BoxDecoration(color: C.tint, borderRadius: BorderRadius.circular(12)),
          child: Text(
              left >= 0
                  ? '${cat!.name}: ${rupees(left)} left of ${rupees(lim)} this month'
                  : '${cat!.name}: over its limit by ${rupees(-left)}',
              style: sans(13, w: FontWeight.w700, color: left >= 0 ? C.forest : C.danger)),
        ),
      ],
      const SizedBox(height: 16),
      Text('Pay with', style: sans(14, w: FontWeight.w700, color: C.text2)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final a in visibleApps)
          Pill(a, selected: a == _app, onTap: () => setState(() => _app = a)),
        Pill('More apps ▸', dashed: true, onTap: _moreApps),
      ]),
      const SizedBox(height: 24),
      AppButton('Pay now', onPressed: () => _continue(s)),
    ]));
  }
}

// ---------------------------------------------------------- Processing

/// Shown while the UPI app is open. On web there is no UPI app, so after a moment
/// we ask the user how it went (the same screen is used when a result is unclear).
class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key, required this.expense});
  final Expense expense;
  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ConfirmScreen(expense: widget.expense)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return _page(Column(children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(
                width: 96,
                height: 96,
                child: CircularProgressIndicator(
                    strokeWidth: 10, color: C.forest, semanticsLabel: 'Waiting for payment')),
            const SizedBox(height: 28),
            Semantics(
                header: true,
                child: Text('Waiting for your payment',
                    textAlign: TextAlign.center, style: serif(30))),
            const SizedBox(height: 10),
            Text('Finish paying in ${widget.expense.upiApp}, then come back.\nWe are checking the result.',
                textAlign: TextAlign.center, style: sans(16, color: C.text2)),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: AppButton('Cancel',
            kind: BtnKind.outlineDark, onPressed: () => Navigator.of(context).pop()),
      ),
    ]));
  }
}

// ------------------------------------------------------------- Confirm

/// Result unclear (or iOS): ask the user. Android can skip this using the UPI app result.
class ConfirmScreen extends StatelessWidget {
  const ConfirmScreen({super.key, required this.expense});
  final Expense expense;

  Future<void> _finish(BuildContext context, String status) async {
    final s = AppScope.of(context);
    final nav = Navigator.of(context);
    final alerts = await s.addExpense(expense.copyWith(status: status));
    if (status == kConfirmed) {
      nav.pushReplacement(MaterialPageRoute(
          builder: (_) => SuccessScreen(expense: expense, alerts: alerts)));
    } else if (status == kFailed) {
      nav.pushReplacement(MaterialPageRoute(builder: (_) => FailedScreen(expense: expense)));
    } else {
      nav.popUntil((r) => r.isFirst);
      toast('Saved as pending. Mark it paid later in History.');
    }
  }

  Widget _row(String a, String b) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(a, style: sans(16, color: C.lightGreen)),
        Flexible(
            child: Text(b,
                textAlign: TextAlign.end,
                style: sans(16, w: FontWeight.w700, color: Colors.white))),
      ]);

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return _page(
      ListView(padding: const EdgeInsets.all(24), children: [
        const BackLink(color: Colors.white),
        Center(
          child: ExcludeSemantics(
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: C.mint, shape: BoxShape.circle),
              child: Center(child: Text('?', style: sans(36, w: FontWeight.w700))),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
            header: true,
            child: Text('Did the payment go through?',
                textAlign: TextAlign.center, style: serif(32, color: Colors.white))),
        const SizedBox(height: 10),
        Text('Confirm so we record it correctly.',
            textAlign: TextAlign.center, style: sans(16, color: const Color(0xFFC9C9C9))),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: C.forest, borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            _row('Paid to', expense.payee.isEmpty ? 'Not set' : expense.payee),
            const SizedBox(height: 12),
            _row('Amount', rupees(expense.amount)),
            const SizedBox(height: 12),
            _row('Category', s.catName(expense.categoryId)),
            const SizedBox(height: 12),
            _row('UPI app', expense.upiApp),
            const SizedBox(height: 12),
            _row('Time', '${dateLabel(expense.createdAt)}, ${timeLabel(expense.createdAt)}'),
          ]),
        ),
        const SizedBox(height: 24),
        AppButton('Yes, paid', kind: BtnKind.light, onPressed: () => _finish(context, kConfirmed)),
        const SizedBox(height: 12),
        AppButton('No, it failed', kind: BtnKind.outline, onPressed: () => _finish(context, kFailed)),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => _finish(context, kPending),
            child: Text('Decide later', style: sans(15, w: FontWeight.w700, color: C.mint)),
          ),
        ),
      ]),
      bg: Colors.black,
    );
  }
}

// ------------------------------------------------------ Success / Failed

Widget _resultCircle(Color color, IconData icon, Color iconColor, String label) => Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, size: 48, color: iconColor, semanticLabel: label),
      ),
    );

/// These screens end the payment flow, so the back gesture goes Home instead of
/// returning to the Pay screen (which could record the same payment twice).
Widget _endOfFlow(BuildContext context, Widget child) => PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).popUntil((r) => r.isFirst);
      },
      child: child,
    );

void _showReceipt(BuildContext context, AppState s, Expense e) {
  Widget row(String a, String b) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(a, style: sans(14, color: C.text2)),
          Flexible(child: Text(b, textAlign: TextAlign.end, style: sans(14, w: FontWeight.w700))),
        ]),
      );
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Receipt'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        row('Paid to', e.payee.isEmpty ? 'Not set' : e.payee),
        row('Amount', rupees(e.amount)),
        row('Category', s.catName(e.categoryId)),
        row('Paid with', e.upiApp.isEmpty ? e.method : '${e.method} · ${e.upiApp}'),
        row('Date and time', '${dateLabel(e.createdAt)}, ${timeLabel(e.createdAt)}'),
        const SizedBox(height: 10),
        Text('This is your own record, not a bank receipt.', style: sans(12, color: C.text2)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
    ),
  );
}

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key, required this.expense, required this.alerts});
  final Expense expense;
  final List<String> alerts;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final cat = s.catById(expense.categoryId);
    final lim = cat?.limit ?? 0;
    final left = lim - s.spentIn(expense.categoryId, expense.createdAt);
    return _endOfFlow(
      context,
      _page(
        ListView(padding: const EdgeInsets.all(24), children: [
          const SizedBox(height: 24),
          _resultCircle(C.mint, Icons.check, Colors.black, 'Success'),
          const SizedBox(height: 16),
          Semantics(
              header: true,
              child: Text('Payment successful',
                  textAlign: TextAlign.center, style: serif(32, color: Colors.white))),
          const SizedBox(height: 8),
          Text(rupees(expense.amount),
              textAlign: TextAlign.center, style: serif(46, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
              'Paid to ${expense.payee.isEmpty ? 'merchant' : expense.payee} · ${s.catName(expense.categoryId)}',
              textAlign: TextAlign.center,
              style: sans(16, color: const Color(0xFFC9C9C9))),
          if (lim > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: C.forest, borderRadius: BorderRadius.circular(16)),
              child: Text(
                  left >= 0
                      ? '${rupees(left)} left in ${s.catName(expense.categoryId)} this month'
                      : '${s.catName(expense.categoryId)} is over its limit by ${rupees(-left)}',
                  textAlign: TextAlign.center,
                  style: sans(15, color: Colors.white)),
            ),
          ],
          for (final a in alerts) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  border: Border.all(color: C.mint, width: 1.5),
                  borderRadius: BorderRadius.circular(16)),
              child: Text(a, style: sans(14, color: Colors.white)),
            ),
          ],
          const SizedBox(height: 24),
          AppButton('View receipt',
              kind: BtnKind.light, onPressed: () => _showReceipt(context, s, expense)),
          const SizedBox(height: 12),
          AppButton('Back to home',
              kind: BtnKind.outline,
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
        ]),
        bg: Colors.black,
      ),
    );
  }
}

class FailedScreen extends StatelessWidget {
  const FailedScreen({super.key, required this.expense});
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    return _endOfFlow(
      context,
      _page(
        ListView(padding: const EdgeInsets.all(24), children: [
          const SizedBox(height: 24),
          _resultCircle(C.danger, Icons.close, Colors.white, 'Failed'),
          const SizedBox(height: 16),
          Semantics(
              header: true,
              child: Text('Payment failed',
                  textAlign: TextAlign.center, style: serif(32, color: Colors.white))),
          const SizedBox(height: 8),
          Text(rupees(expense.amount),
              textAlign: TextAlign.center, style: serif(46, color: Colors.white)),
          const SizedBox(height: 8),
          Text('to ${expense.payee.isEmpty ? 'the merchant' : expense.payee} was not paid',
              textAlign: TextAlign.center, style: sans(16, color: const Color(0xFFC9C9C9))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: C.forest, borderRadius: BorderRadius.circular(16)),
            child: Text('Nothing was added to your spending.',
                textAlign: TextAlign.center, style: sans(15, color: Colors.white)),
          ),
          const SizedBox(height: 24),
          AppButton('Try again', kind: BtnKind.light, onPressed: () => Navigator.of(context).pop()),
          const SizedBox(height: 12),
          AppButton('Back to home',
              kind: BtnKind.outline,
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
        ]),
        bg: Colors.black,
      ),
    );
  }
}

// -------------------------------------------------------- Add manually

class AddManualScreen extends StatefulWidget {
  const AddManualScreen({super.key});
  @override
  State<AddManualScreen> createState() => _AddManualScreenState();
}

class _AddManualScreenState extends State<AddManualScreen> {
  final _amount = TextEditingController();
  final _payee = TextEditingController();
  final _note = TextEditingController();
  String? _catId;
  String? _method;
  DateTime _when = DateTime.now();

  @override
  void dispose() {
    _amount.dispose();
    _payee.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
        context: context,
        initialDate: _when,
        firstDate: DateTime(2020),
        lastDate: DateTime.now());
    if (d != null) _setWhen(DateTime(d.year, d.month, d.day, _when.hour, _when.minute));
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_when));
    if (t != null) _setWhen(DateTime(_when.year, _when.month, _when.day, t.hour, t.minute));
  }

  void _setWhen(DateTime d) {
    final now = DateTime.now();
    setState(() => _when = d.isAfter(now) ? now : d); // no future transactions
  }

  Future<void> _save(AppState s) async {
    final amount = parseMoney(_amount.text);
    if (amount == null || amount <= 0) {
      toast('Enter the amount.');
      return;
    }
    final nav = Navigator.of(context);
    final e = Expense(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      amount: amount,
      categoryId: _catId ?? s.categories.first.id,
      payee: _payee.text.trim(),
      upiId: '',
      upiApp: '',
      method: _method ?? s.lastMethod,
      note: _note.text.trim(),
      status: kConfirmed,
      createdAt: _when,
    );
    final alerts = await s.addExpense(e);
    nav.pop();
    toast(alerts.isNotEmpty ? alerts.join('\n') : 'Expense added.');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final suggested = s.payeeCategory[_payee.text.trim()];
    _catId ??= s.categories.first.id;
    final method = _method ?? s.lastMethod;
    return _page(ListView(padding: const EdgeInsets.all(24), children: [
      const BackLink(),
      Text('Add expense', style: serif(30)),
      const SizedBox(height: 12),
      _amountBox(_amount, 'Amount'),
      const SizedBox(height: 12),
      AppField(
          label: 'Paid to (optional)',
          controller: _payee,
          hint: 'e.g. Ramesh, local market',
          onChanged: (v) {
            final c = s.payeeCategory[v.trim()];
            if (c != null) setState(() => _catId = c);
          }),
      const SizedBox(height: 16),
      Text('Category', style: sans(14, w: FontWeight.w700, color: C.text2)),
      const SizedBox(height: 8),
      CategoryChooser(
          state: s,
          selectedId: _catId!,
          suggestedId: suggested,
          onSelected: (id) => setState(() => _catId = id)),
      const SizedBox(height: 16),
      Text('Payment method', style: sans(14, w: FontWeight.w700, color: C.text2)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final m in kMethods)
          Pill(m, selected: m == method, onTap: () => setState(() => _method = m)),
      ]),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
            flex: 3,
            child: PickerField(label: 'Date', value: dateLabel(_when), onTap: _pickDate)),
        const SizedBox(width: 10),
        Expanded(
            flex: 2,
            child: PickerField(label: 'Time', value: timeLabel(_when), onTap: _pickTime)),
      ]),
      const SizedBox(height: 12),
      AppField(label: 'Note (optional)', controller: _note, hint: 'e.g. lunch with team'),
      const SizedBox(height: 20),
      AppButton('Save expense', onPressed: () => _save(s)),
    ]));
  }
}
