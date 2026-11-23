#!/usr/bin/env bash
# One-time setup: creates the web, Android and iOS folders and sets display names.
set -e
cd "$(dirname "$0")"
flutter create . --project-name expense_tracker --org com.example --platforms=web,android,ios
flutter pub get
sed -i 's/android:label="expense_tracker"/android:label="Expense Tracker"/' android/app/src/main/AndroidManifest.xml 2>/dev/null || true
sed -i 's#<title>expense_tracker</title>#<title>Expense Tracker</title>#; s#content="expense_tracker"#content="Expense Tracker"#' web/index.html 2>/dev/null || true
sed -i 's#"name": "expense_tracker"#"name": "Expense Tracker"#; s#"short_name": "expense_tracker"#"short_name": "Expense Tracker"#' web/manifest.json 2>/dev/null || true
echo
echo "Done. Start the app with:  flutter run -d chrome"
