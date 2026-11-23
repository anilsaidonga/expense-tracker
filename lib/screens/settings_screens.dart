import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';

Widget _page(Widget child) => Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        const TopBar(),
        Expanded(child: child),
      ]),
    );

/// Light / Dark / System. The choice is saved; dark colors are not applied yet.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  Widget _preview(String kind) {
    Widget half(Color bg) => Expanded(
          child: Container(color: bg, child: Column(children: [
            Container(height: 12, color: C.mint),
          ])),
        );
    return ExcludeSemantics(
      child: Container(
        width: 76,
        height: 54,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBDBDBD))),
        child: Row(children: [
          if (kind != 'Dark') half(Colors.white),
          if (kind != 'Light') half(const Color(0xFF121212)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    const options = [
      ['Light', 'Bright background'],
      ['Dark', 'Easier on the eyes at night'],
      ['System', 'Matches your phone setting'],
    ];
    return _page(ListView(padding: const EdgeInsets.all(24), children: [
      const BackLink(),
      Semantics(header: true, child: Text('Appearance', style: serif(30))),
      const SizedBox(height: 6),
      Text('Choose how the app looks.', style: sans(15, color: C.text2)),
      const SizedBox(height: 16),
      for (final o in options)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Semantics(
            button: true,
            selected: s.themeChoice == o[0],
            label: '${o[0]}. ${o[1]}',
            excludeSemantics: true,
            onTap: () => s.setThemeChoice(o[0]),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => s.setThemeChoice(o[0]),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: C.grey,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: s.themeChoice == o[0] ? Colors.black : C.grey, width: 2),
                ),
                child: Row(children: [
                  _preview(o[0]),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(o[0], style: sans(16, w: FontWeight.w700)),
                      Text(o[1], style: sans(13, color: C.text2)),
                    ]),
                  ),
                  Icon(s.themeChoice == o[0]
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off),
                ]),
              ),
            ),
          ),
        ),
      const SizedBox(height: 4),
      Text('Dark mode is coming soon. Your choice is saved.', style: sans(13, color: C.text2)),
    ]));
  }
}

/// Simple text page used for About, Help and Security while real content is pending.
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key, required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) {
    return _page(ListView(padding: const EdgeInsets.all(24), children: [
      const BackLink(),
      Semantics(header: true, child: Text(title, style: serif(30))),
      const SizedBox(height: 12),
      Text(body, style: sans(16, color: C.text2)),
    ]));
  }
}
