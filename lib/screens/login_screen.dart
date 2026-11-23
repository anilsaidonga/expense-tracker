import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'onboarding_screens.dart';

/// Log in with a mobile number and a code. (Demo: any 6-digit code is accepted.)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobile = TextEditingController();

  @override
  void dispose() {
    _mobile.dispose();
    super.dispose();
  }

  void _send() {
    final s = AppScope.of(context);
    final m = normMobile(_mobile.text);
    if (m.length != 10) {
      toast('Enter a valid 10-digit mobile number.');
      return;
    }
    if (s.mobile != m) {
      toast('No account found for this number. Create an account first.');
      return;
    }
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => OtpScreen(mobile: m, signup: false)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(children: [
        const TopBar(),
        ForestBlock(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 40),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              header: true,
              child: Text('Spend smart.\nStay in budget.', style: serif(40, color: Colors.white)),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Log in with your mobile number. We will send you a code.',
                  style: sans(17, color: Colors.white)),
              const SizedBox(height: 20),
              AppField(
                  label: 'Mobile number',
                  controller: _mobile,
                  onDark: true,
                  hint: '+91 98765 43210',
                  keyboard: TextInputType.phone),
              const SizedBox(height: 20),
              AppButton('Send OTP', kind: BtnKind.light, onPressed: _send),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const SignupScreen())),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  child: Text('New here? Create account',
                      style: sans(15, w: FontWeight.w700, color: C.mint)),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Sign-up step 1: name, mobile number, optional email.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    super.dispose();
  }

  void _continue() {
    final s = AppScope.of(context);
    final name = _name.text.trim();
    final m = normMobile(_mobile.text);
    final e = _email.text.trim();
    if (name.isEmpty) {
      toast('Enter your full name.');
      return;
    }
    if (m.length != 10) {
      toast('Enter a valid 10-digit mobile number.');
      return;
    }
    if (e.isNotEmpty && (!e.contains('@') || !e.contains('.'))) {
      toast('Enter a valid email, or leave it empty.');
      return;
    }
    if (s.mobile == m) {
      toast('An account with this number already exists. Please log in.');
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OtpScreen(mobile: m, signup: true, name: name, email: e)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        const TopBar(),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(24), children: [
            const BackLink(),
            const StepDots(1),
            const SizedBox(height: 20),
            Semantics(header: true, child: Text('Create your account', style: serif(30))),
            const SizedBox(height: 6),
            Text('Let us set up your personal finance assistant.',
                style: sans(15, color: C.text2)),
            const SizedBox(height: 20),
            AppField(label: 'Full name', controller: _name, hint: 'Your full name'),
            const SizedBox(height: 14),
            AppField(
                label: 'Mobile number',
                controller: _mobile,
                hint: '+91',
                keyboard: TextInputType.phone),
            const SizedBox(height: 14),
            AppField(
                label: 'Email (optional)',
                controller: _email,
                hint: 'name@example.com',
                keyboard: TextInputType.emailAddress),
            const SizedBox(height: 24),
            AppButton('Continue', onPressed: _continue),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: Text('Already have an account? Log in',
                    style: sans(15, w: FontWeight.w700, color: C.forest)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Enter the 6-digit code. Used by both sign-up and login.
class OtpScreen extends StatefulWidget {
  const OtpScreen(
      {super.key, required this.mobile, required this.signup, this.name = '', this.email = ''});
  final String mobile;
  final bool signup;
  final String name;
  final String email;
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _c = TextEditingController();
  final _f = FocusNode();

  @override
  void dispose() {
    _c.dispose();
    _f.dispose();
    super.dispose();
  }

  String get _shown => '+91 ${widget.mobile.substring(0, 5)} ${widget.mobile.substring(5)}';

  Future<void> _verify() async {
    if (_c.text.length != 6) {
      toast('Enter the 6-digit code.');
      return;
    }
    final s = AppScope.of(context);
    final nav = Navigator.of(context);
    if (widget.signup) {
      await s.createProfile(
          name: widget.name, mobileNumber: widget.mobile, emailAddr: widget.email);
      nav.pushReplacement(MaterialPageRoute(builder: (_) => const AboutScreen()));
    } else {
      await s.signIn();
      nav.popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _c.text;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        const TopBar(),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(24), children: [
            const BackLink(),
            Semantics(header: true, child: Text('Verify your number', style: serif(30))),
            const SizedBox(height: 6),
            Text('Enter the 6-digit code we sent to $_shown.', style: sans(15, color: C.text2)),
            const SizedBox(height: 20),
            Stack(children: [
              ExcludeSemantics(
                child: GestureDetector(
                  onTap: () => _f.requestFocus(),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    for (var i = 0; i < 6; i++)
                      Container(
                        width: 48,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: C.grey,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: i == code.length ? Colors.black : C.grey, width: 2),
                        ),
                        child: Text(i < code.length ? code[i] : '', style: serif(26)),
                      ),
                  ]),
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  child: Semantics(
                    label: '6-digit verification code',
                    textField: true,
                    child: TextField(
                      controller: _c,
                      focusNode: _f,
                      autofocus: true,
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      decoration:
                          const InputDecoration(counterText: '', border: InputBorder.none),
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Center(
              child: TextButton(
                onPressed: () => toast('Code sent again (demo).'),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: Text('Resend code', style: sans(14, w: FontWeight.w700, color: C.forest)),
              ),
            ),
            Center(
                child: Text('Demo: any 6-digit code works for now.',
                    style: sans(13, color: C.text2))),
            const SizedBox(height: 20),
            AppButton('Verify', onPressed: _verify),
          ]),
        ),
      ]),
    );
  }
}
