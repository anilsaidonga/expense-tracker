# Expense Tracker (working name)

Flutter app, built for a client. Web first, then Android, then iOS. Users record every kind of
payment (UPI scan, cash, card, other), set a monthly limit per category and get alerts.

## Current state
Runs on web with data saved in the browser (`shared_preferences`) and a demo account.
All data code is in `lib/app_state.dart`, so swapping in Firebase later is contained there.

## Features built
- Per-category monthly limits; total budget = sum of limits. Home donut + category summary,
  "View all" screen to edit categories, limits and alerts; "Set monthly budget" screen.
- Alerts: per category (slider 10-100% in steps of 5 plus a typed box, and a "limit crossed"
  switch) and for the total. Each alert fires once per month. Bell on Home lists past alerts.
- Notification settings: defaults, total budget, daily summary (not active), channels:
  in-app, email and WhatsApp (choice and contact saved; sending needs a server, not built).
- "+" button: Scan to pay (web: paste a UPI link or ID) or Add manually.
- Pay screen after scan: amount, category (3 chips + More with search), UPI app (2 + More).
- Confirm screen: Yes paid / Failed / Decide later. Android should use the UPI app result later.
- Expenses store date AND time, payment method (Cash, Card, UPI, Other), payee, note, status.
- History and Reports have a month picker. Reports show a donut and legend.

## Sign-up and login (built)
Login uses a mobile number and a 6-digit code. Sign-up: step 1 name, mobile, optional email,
code; steps 2 (about you), 3 (monthly details) and 4 (set budget) are skippable. Demo only: any
6-digit code works, and one account is kept in the browser. Real codes need Firebase phone login
(SMS may cost money).

## Payment flow (built)
Scan (web: paste a UPI link) -> Pay (amount, category, app) -> Waiting -> Confirm if unclear ->
Success or Failed. On web there is no UPI app, so the Waiting screen always ends at Confirm.
Success and Failed block the back gesture and offer "Back to home", so a payment is never saved twice.

## Navigation and accessibility rules
- Drill-down screens use the shared BackLink (arrow + "Back"). The scan overlay uses "Close".
  Sign-up steps 2 to 4 have "Skip for now" instead of Back.
- Touch targets are at least 44-48 px; heights are minimums so large text sizes still fit.
- Fields, switches, sliders, charts and date pickers have screen reader labels; decorative
  shapes are hidden from screen readers. Keep this when adding screens.

## Not built yet (next steps, in order)
1. Firebase: real accounts, phone codes and cloud data. Keep data access in app_state.dart.
2. Dark mode (the Appearance screen only saves the choice).
3. Android: real UPI launch and result (a UPI package), installed-app detection.
4. iOS: no result from UPI apps, so the Confirm screen appears on return.
5. Email and WhatsApp sending from a server (WhatsApp uses Meta's business platform, paid per
   message, needs approved templates and user consent).
6. Real content for Security & privacy, Help & support and About.

## Decisions
- Income tracking is NOT supported (client confirmed). Do not add income screens.
- Payment method is kept but optional; scanned UPI payments are set to UPI automatically.
- App name is undecided; keep it in the single constant `appName` (lib/theme.dart).
- Alert level and "crossed" alert: a category stores a value only if it differs from the default.
- Deleting a category moves its expenses to "Others". "Others" cannot be deleted.

## Design
Mint top bar, deep forest green and black sections, serif headings (Fraunces), DM Sans body,
grey rounded cards, full-width rounded buttons, black bottom bar with a white "+" pill.
Colors and fonts live in lib/theme.dart (class C, serif(), sans()).
- Mint #58B380, Forest #1E4A36, Forest mid #2D6A4F, Forest dark #173B2B, Black #000
- Card grey #F2F2F2, text grey #4A4A4A, light green #B9D4C5, danger #B42318

## Code map
- lib/models.dart: Category, Expense, AlertEntry, money and date helpers, UPI link parser
- lib/app_state.dart: all data, alert rules, saving
- lib/widgets.dart: shared widgets (top bar, nav, donut chart, month picker, pickers, sliders)
- lib/screens/: login_screen (login, sign-up, code), onboarding_screens (steps 2-3),
  home_shell (Home, History, Reports, Profile), categories_screen (list, edit, budget step),
  notifications_screen, settings_screens (appearance, info), payment_flow (scan, pay, waiting,
  confirm, success, failed, add manually)

## Rules for changes
- Keep one screen per file area above; reuse widgets.dart before adding new widgets.
- No hard-coded colors outside lib/theme.dart where possible.
- Handle empty states. Test the UPI flow on a real Android phone.
- Run `flutter test` and `flutter analyze` before finishing.
