# Expense Tracker

Flutter app (web first, then Android and iOS) for tracking expenses with a limit for each
category, alerts, manual and UPI-scan entry, monthly reports and a month picker.

## First run

1. Install Flutter and check it with `flutter doctor`.
2. In this folder run: `bash setup.sh`
   (creates the web, Android and iOS folders, installs packages, sets the display name)
3. Start: `flutter run -d chrome`

Run the tests with `flutter test`.

## Notes
- Data is saved in the browser for now. Sign-up and login are a demo: create an account with a
  mobile number, then any 6-digit code works.
- The app name is one constant, `appName`, in `lib/theme.dart`.
- See `CLAUDE.md` for the full project context.
