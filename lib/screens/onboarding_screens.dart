import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'categories_screen.dart';

// Steps 2 to 4 of sign-up can all be skipped. They have no Back link: each step
// replaces the previous one, so going back would only repeat sign-up.

Widget _stepPage(List<Widget> children) => Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        const TopBar(),
        Expanded(child: ListView(padding: const EdgeInsets.all(24), children: children)),
      ]),
    );

Widget _skip(VoidCallback onTap) => Center(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        child: Text('Skip for now', style: sans(16, w: FontWeight.w700, color: C.forest)),
      ),
    );

/// Sign-up step 2 (skippable): date of birth and gender.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});
  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  DateTime? _dob;
  String _gender = '';

  Future<void> _pick() async {
    final d = await showDatePicker(
        context: context,
        initialDate: _dob ?? DateTime(2000),
        firstDate: DateTime(1920),
        lastDate: DateTime.now());
    if (d != null) setState(() => _dob = d);
  }

  void _next() => Navigator.of(context)
      .pushReplacement(MaterialPageRoute(builder: (_) => const DetailsScreen()));

  Future<void> _continue() async {
    final s = AppScope.of(context);
    await s.updateProfile(
      dobText: _dob == null ? null : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
      genderText: _gender.isEmpty ? null : _gender,
    );
    if (mounted) _next();
  }

  @override
  Widget build(BuildContext context) {
    return _stepPage([
      const StepDots(2),
      const SizedBox(height: 20),
      Semantics(header: true, child: Text('Tell us more about you', style: serif(30))),
      const SizedBox(height: 6),
      Text('Optional. You can skip this and add it later.', style: sans(15, color: C.text2)),
      const SizedBox(height: 20),
      PickerField(
        label: 'Date of birth',
        value: _dob == null ? 'DD/MM/YYYY' : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
        onTap: _pick,
      ),
      const SizedBox(height: 16),
      Semantics(header: true, child: Text('Gender', style: sans(14, color: C.text2))),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final g in const ['Male', 'Female', 'Other'])
          Pill(g,
              selected: _gender == g,
              onTap: () => setState(() => _gender = _gender == g ? '' : g)),
      ]),
      const SizedBox(height: 24),
      AppButton('Continue', onPressed: _continue),
      const SizedBox(height: 8),
      _skip(_next),
    ]);
  }
}

/// Sign-up step 3 (skippable): monthly salary and location.
class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});
  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final _salary = TextEditingController();
  final _location = TextEditingController();

  @override
  void dispose() {
    _salary.dispose();
    _location.dispose();
    super.dispose();
  }

  void _next() => Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const BudgetsScreen(onboarding: true)));

  Future<void> _continue() async {
    final t = _salary.text.trim();
    double? sal;
    if (t.isNotEmpty) {
      sal = parseMoney(t);
      if (sal == null || sal < 0) {
        toast('Enter a valid amount, or skip.');
        return;
      }
    }
    final s = AppScope.of(context);
    await s.updateProfile(
        salaryValue: sal,
        locationText: _location.text.trim().isEmpty ? null : _location.text.trim());
    if (mounted) _next();
  }

  @override
  Widget build(BuildContext context) {
    return _stepPage([
      const StepDots(3),
      const SizedBox(height: 20),
      Semantics(header: true, child: Text('Your monthly details', style: serif(30))),
      const SizedBox(height: 6),
      Text('Optional. This helps us suggest a budget.', style: sans(15, color: C.text2)),
      const SizedBox(height: 20),
      AppField(
          label: 'Monthly salary (₹)',
          controller: _salary,
          hint: '50,000',
          keyboard: TextInputType.number),
      const SizedBox(height: 14),
      AppField(label: 'Location', controller: _location, hint: 'City'),
      const SizedBox(height: 24),
      AppButton('Continue', onPressed: _continue),
      const SizedBox(height: 8),
      _skip(_next),
    ]);
  }
}
