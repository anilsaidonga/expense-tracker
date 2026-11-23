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

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _email(BuildContext context, AppState s, bool on) async {
    if (!on) {
      await s.setChannels(emailOn: false);
      return;
    }
    final c = TextEditingController(text: s.alertEmail);
    String? err;
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Get alerts by email'),
          content: TextField(
            controller: c,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
                labelText: 'Email address', hintText: 'name@example.com', errorText: err),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final v = c.text.trim();
                if (!v.contains('@') || !v.contains('.')) {
                  setS(() => err = 'Enter a valid email.');
                  return;
                }
                Navigator.pop(ctx, v);
              },
              child: const Text('Turn on'),
            ),
          ],
        ),
      ),
    );
    if (r != null) await s.setChannels(emailOn: true, emailAddr: r);
  }

  Future<void> _whatsapp(BuildContext context, AppState s, bool on) async {
    if (!on) {
      await s.setChannels(waOn: false);
      return;
    }
    final c = TextEditingController(
        text: s.whatsappNumber.isNotEmpty ? s.whatsappNumber : s.formattedMobile);
    var agreed = false;
    String? err;
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Get alerts on WhatsApp'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(
              controller: c,
              autofocus: true,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                  labelText: 'WhatsApp number', hintText: '+91 98765 43210', errorText: err),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: agreed,
              onChanged: (v) => setS(() => agreed = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                  'I agree to receive budget alerts on WhatsApp. I can turn this off any time.',
                  style: sans(14)),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: agreed
                  ? () {
                      final digits = c.text.replaceAll(RegExp(r'[^0-9]'), '');
                      if (digits.length < 10) {
                        setS(() => err = 'Enter a valid number.');
                        return;
                      }
                      Navigator.pop(ctx, c.text.trim());
                    }
                  : null,
              child: const Text('Turn on'),
            ),
          ],
        ),
      ),
    );
    if (r != null) await s.setChannels(waOn: true, waNumber: r);
  }

  Widget _change(VoidCallback onTap) => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        child: Text('Change', style: sans(14, w: FontWeight.w700, color: C.forest)),
      );

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return _page(ListView(padding: const EdgeInsets.all(24), children: [
      const BackLink(),
      Text('Notifications', style: serif(30)),
      const SizedBox(height: 6),
      Text('Defaults for all categories. Any category can use its own level.',
          style: sans(15, color: C.text2)),
      const SizedBox(height: 20),
      const SectionLabel('Category alerts'),
      SectionCard(rows: [
        SettingRow(
          title: 'Alert me as categories fill up',
          sub: "Uses each category's limit",
          trailing: Switch(value: s.catAlerts, onChanged: (v) => s.setNotificationSettings(cat: v)),
        ),
        if (s.catAlerts)
          LevelSlider(
            label: 'Default alert level',
            value: s.defaultAlertAt,
            onChanged: (v) => s.setNotificationSettings(level: v),
            helper: 'Used by categories without their own level.',
          ),
        SettingRow(
          title: 'Alert when a limit is crossed',
          sub: 'Once per category each month',
          trailing: Switch(
              value: s.defaultCross, onChanged: (v) => s.setNotificationSettings(cross: v)),
        ),
      ]),
      const SizedBox(height: 20),
      const SectionLabel('Total budget and summary'),
      SectionCard(rows: [
        SettingRow(
          title: 'Total monthly budget alerts',
          trailing: Switch(
              value: s.totalAlerts, onChanged: (v) => s.setNotificationSettings(total: v)),
        ),
        SettingRow(
          title: 'Daily spending summary',
          sub: 'Not active yet',
          trailing: Switch(
              value: s.dailySummary, onChanged: (v) => s.setNotificationSettings(daily: v)),
        ),
      ]),
      const SizedBox(height: 20),
      const SectionLabel('How you get alerts'),
      SectionCard(rows: [
        const SettingRow(
          title: 'In-app alerts',
          sub: 'Shown on the bell',
          trailing: Switch(value: true, onChanged: null),
        ),
        SettingRow(
          title: 'Email',
          sub: s.emailAlerts ? 'Sends to ${s.alertEmail}' : 'Get alerts by email',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (s.emailAlerts) _change(() => _email(context, s, true)),
            Semantics(
                label: 'Email alerts',
                child: Switch(value: s.emailAlerts, onChanged: (v) => _email(context, s, v))),
          ]),
        ),
        SettingRow(
          title: 'WhatsApp',
          sub: s.whatsappAlerts ? 'Sends to ${s.whatsappNumber}' : 'Add your number to turn on',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (s.whatsappAlerts) _change(() => _whatsapp(context, s, true)),
            Semantics(
                label: 'WhatsApp alerts',
                child: Switch(
                    value: s.whatsappAlerts, onChanged: (v) => _whatsapp(context, s, v))),
          ]),
        ),
      ]),
      const SizedBox(height: 12),
      Text('Your email and WhatsApp choices are saved. Messages start once the cloud service is connected.',
          style: sans(13, color: C.text2)),
    ]));
  }
}

/// The bell on Home: a list of past alerts.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return _page(ListView(padding: const EdgeInsets.all(24), children: [
      const BackLink(),
      Text('Alerts', style: serif(30)),
      const SizedBox(height: 6),
      Text('Your recent budget alerts.', style: sans(15, color: C.text2)),
      const SizedBox(height: 16),
      if (s.alertLog.isEmpty) Text('No alerts yet.', style: sans(16, color: C.text2)),
      for (final a in s.alertLog)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GreyCard(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.message, style: sans(15, w: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('${dateLabel(a.at)}, ${timeLabel(a.at)}', style: sans(13, color: C.text2)),
            ]),
          ),
        ),
    ]));
  }
}
