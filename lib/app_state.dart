import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// All app data lives here. Right now it is saved in the browser
/// (shared_preferences). Later, replace load/save with Firebase.
class AppState extends ChangeNotifier {
  late SharedPreferences _p;
  // Profile. The mobile number (10 digits) is the account id.
  String? mobile;
  String fullName = '';
  String email = ''; // optional
  String dob = '';
  String gender = '';
  double? salary;
  String location = '';
  bool signedIn = false;
  String themeChoice = 'Light';
  List<Category> categories = defaultCategories();
  List<Expense> expenses = [];

  // Notification defaults (each category can override level and crossed alert).
  bool catAlerts = true;
  int defaultAlertAt = 80;
  bool defaultCross = true;
  bool totalAlerts = true;
  bool dailySummary = false;

  Map<String, List<String>> alerted = {}; // month key -> alerts already shown
  List<AlertEntry> alertLog = [];
  Map<String, String> payeeCategory = {}; // payee -> last used category id
  String lastMethod = 'Cash';

  // Alert channels. The choice is saved here; sending needs a server later.
  bool emailAlerts = false;
  String alertEmail = '';
  bool whatsappAlerts = false;
  String whatsappNumber = '';

  bool get loggedIn => signedIn && mobile != null;

  String get displayName {
    final n = fullName.trim().split(' ').first;
    return n.isEmpty ? 'there' : n;
  }

  String get formattedMobile {
    final m = mobile ?? '';
    return m.length == 10 ? '+91 ${m.substring(0, 5)} ${m.substring(5)}' : m;
  }

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    signedIn = _p.getBool('signedIn') ?? false;
    final raw = _p.getString('data');
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      categories = ((m['categories'] as List?) ?? [])
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
      if (categories.isEmpty) categories = defaultCategories();
      if (!categories.any((c) => c.id == kOtherId)) {
        categories.add(const Category(id: kOtherId, name: 'Others'));
      }
      expenses = ((m['expenses'] as List?) ?? [])
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList();
      catAlerts = (m['catAlerts'] as bool?) ?? true;
      defaultAlertAt = (m['defaultAlertAt'] as num?)?.toInt() ?? 80;
      defaultCross = (m['defaultCross'] as bool?) ?? true;
      totalAlerts = (m['totalAlerts'] as bool?) ?? true;
      dailySummary = (m['dailySummary'] as bool?) ?? false;
      alerted = ((m['alerted'] as Map?) ?? {})
          .map((k, v) => MapEntry(k as String, List<String>.from(v as List)));
      alertLog = ((m['alertLog'] as List?) ?? [])
          .map((e) => AlertEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      payeeCategory = ((m['payeeCategory'] as Map?) ?? {})
          .map((k, v) => MapEntry(k as String, v as String));
      lastMethod = (m['lastMethod'] as String?) ?? 'Cash';
      emailAlerts = (m['emailAlerts'] as bool?) ?? false;
      alertEmail = (m['alertEmail'] as String?) ?? '';
      whatsappAlerts = (m['whatsappAlerts'] as bool?) ?? false;
      whatsappNumber = (m['whatsappNumber'] as String?) ?? '';
      mobile = m['mobile'] as String?;
      fullName = (m['fullName'] as String?) ?? '';
      email = (m['profileEmail'] as String?) ?? '';
      dob = (m['dob'] as String?) ?? '';
      gender = (m['gender'] as String?) ?? '';
      salary = (m['salary'] as num?)?.toDouble();
      location = (m['location'] as String?) ?? '';
      themeChoice = (m['themeChoice'] as String?) ?? 'Light';
    } catch (_) {
      // Saved data was unreadable: continue with whatever loaded.
    }
  }

  Future<void> _save() async {
    await _p.setString(
      'data',
      jsonEncode({
        'categories': categories.map((c) => c.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'catAlerts': catAlerts,
        'defaultAlertAt': defaultAlertAt,
        'defaultCross': defaultCross,
        'totalAlerts': totalAlerts,
        'dailySummary': dailySummary,
        'alerted': alerted,
        'alertLog': alertLog.map((a) => a.toJson()).toList(),
        'payeeCategory': payeeCategory,
        'lastMethod': lastMethod,
        'emailAlerts': emailAlerts,
        'alertEmail': alertEmail,
        'whatsappAlerts': whatsappAlerts,
        'whatsappNumber': whatsappNumber,
        'mobile': mobile,
        'fullName': fullName,
        'profileEmail': email,
        'dob': dob,
        'gender': gender,
        'salary': salary,
        'location': location,
        'themeChoice': themeChoice,
      }),
    );
  }

  Future<void> _commit() async {
    await _save();
    notifyListeners();
  }

  // ---- Account (demo: the code is not checked; real login comes with Firebase) ----
  void _resetData() {
    categories = defaultCategories();
    expenses = [];
    alerted = {};
    alertLog = [];
    payeeCategory = {};
    lastMethod = 'Cash';
    emailAlerts = false;
    alertEmail = '';
    whatsappAlerts = false;
    whatsappNumber = '';
    dob = '';
    gender = '';
    salary = null;
    location = '';
  }

  Future<void> createProfile(
      {required String name, required String mobileNumber, String emailAddr = ''}) async {
    if (mobile != null && mobile != mobileNumber) _resetData();
    mobile = mobileNumber;
    fullName = name.trim();
    email = emailAddr.trim();
    signedIn = false;
    await _p.setBool('signedIn', false);
    await _commit();
  }

  Future<void> updateProfile(
      {String? dobText, String? genderText, double? salaryValue, String? locationText}) async {
    dob = dobText ?? dob;
    gender = genderText ?? gender;
    salary = salaryValue ?? salary;
    location = locationText ?? location;
    await _commit();
  }

  Future<void> signIn() async {
    if (alertEmail.isEmpty) alertEmail = email;
    signedIn = true;
    await _p.setBool('signedIn', true);
    await _commit();
  }

  Future<void> logout() async {
    signedIn = false;
    await _p.setBool('signedIn', false);
    notifyListeners();
  }

  Future<void> setThemeChoice(String v) async {
    themeChoice = v;
    await _commit();
  }

  // ---- Categories and limits ----
  String catName(String id) => categories
      .firstWhere((c) => c.id == id,
          orElse: () => const Category(id: kOtherId, name: 'Others'))
      .name;

  Category? catById(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  int alertLevelOf(Category c) => c.alertAt ?? defaultAlertAt;
  bool crossAlertOf(Category c) => c.alertOnCross ?? defaultCross;

  double get totalBudget => categories.fold(0.0, (a, c) => a + (c.limit ?? 0));

  void _resetFired(String? catId) {
    final list = alerted[monthKey(DateTime.now())];
    if (list == null) return;
    list.removeWhere((k) => k.startsWith('total:') || (catId != null && k.startsWith('cat:$catId:')));
  }

  Future<Category> addCategory(String name,
      {double? limit, bool notify = true, int? alertAt, bool? cross}) async {
    final same = categories.where((c) => c.name.toLowerCase() == name.trim().toLowerCase());
    if (same.isNotEmpty) return same.first; // no duplicate names
    final c = Category(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      isCustom: true,
      limit: limit,
      notify: notify,
      alertAt: alertAt,
      alertOnCross: cross,
    );
    categories.add(c);
    _resetFired(null);
    await _commit();
    return c;
  }

  Future<void> updateCategory(String id,
      {required String name,
      double? limit,
      required bool notify,
      int? alertAt,
      bool? cross}) async {
    final i = categories.indexWhere((c) => c.id == id);
    if (i < 0) return;
    final old = categories[i];
    categories[i] = Category(
      id: id,
      name: name.trim().isEmpty ? old.name : name.trim(),
      isCustom: old.isCustom,
      limit: limit,
      notify: notify,
      alertAt: alertAt,
      alertOnCross: cross,
    );
    if (old.limit != limit) _resetFired(id);
    await _commit();
  }

  /// Bulk update from the "Set monthly budget" screen.
  Future<void> setLimits(Map<String, double?> limits) async {
    for (var i = 0; i < categories.length; i++) {
      final c = categories[i];
      if (!limits.containsKey(c.id)) continue;
      final l = limits[c.id];
      if (l != c.limit) {
        categories[i] = Category(
          id: c.id,
          name: c.name,
          isCustom: c.isCustom,
          limit: l,
          notify: c.notify,
          alertAt: c.alertAt,
          alertOnCross: c.alertOnCross,
        );
        _resetFired(c.id);
      }
    }
    await _commit();
  }

  /// Expenses in the deleted category move to "Others".
  Future<void> deleteCategory(String id) async {
    if (id == kOtherId) return;
    categories.removeWhere((c) => c.id == id);
    expenses = expenses
        .map((e) => e.categoryId == id ? e.copyWith(categoryId: kOtherId) : e)
        .toList();
    payeeCategory.removeWhere((k, v) => v == id);
    await _commit();
  }

  Future<void> setNotificationSettings(
      {bool? cat, int? level, bool? cross, bool? total, bool? daily}) async {
    catAlerts = cat ?? catAlerts;
    defaultAlertAt = level ?? defaultAlertAt;
    defaultCross = cross ?? defaultCross;
    totalAlerts = total ?? totalAlerts;
    dailySummary = daily ?? dailySummary;
    await _commit();
  }

  Future<void> setChannels(
      {bool? emailOn, String? emailAddr, bool? waOn, String? waNumber}) async {
    emailAlerts = emailOn ?? emailAlerts;
    alertEmail = emailAddr ?? alertEmail;
    whatsappAlerts = waOn ?? whatsappAlerts;
    whatsappNumber = waNumber ?? whatsappNumber;
    await _commit();
  }

  // ---- Expenses ----
  Iterable<Expense> expensesIn(DateTime month) =>
      expenses.where((e) => sameMonth(e.createdAt, month));

  Iterable<Expense> _countedIn(DateTime month) =>
      expensesIn(month).where((e) => e.status == kConfirmed);

  double totalIn(DateTime month) =>
      _countedIn(month).fold(0.0, (a, e) => a + e.amount);

  Map<String, double> byCategoryIn(DateTime month) {
    final m = <String, double>{};
    for (final e in _countedIn(month)) {
      m[e.categoryId] = (m[e.categoryId] ?? 0) + e.amount;
    }
    return m;
  }

  double spentIn(String catId, DateTime month) => byCategoryIn(month)[catId] ?? 0;
  double get monthTotal => totalIn(DateTime.now());

  DateTime? get earliest {
    if (expenses.isEmpty) return null;
    return expenses.map((e) => e.createdAt).reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// Returns alert messages to show (empty if none).
  Future<List<String>> addExpense(Expense e) async {
    expenses.add(e);
    if (e.payee.isNotEmpty && e.status == kConfirmed) payeeCategory[e.payee] = e.categoryId;
    lastMethod = e.method;
    final alerts = e.status == kConfirmed ? _checkAlerts(e) : <String>[];
    await _commit();
    return alerts;
  }

  Future<List<String>> setStatus(String id, String status) async {
    final i = expenses.indexWhere((x) => x.id == id);
    if (i < 0) return [];
    expenses[i] = expenses[i].copyWith(status: status);
    final alerts = status == kConfirmed ? _checkAlerts(expenses[i]) : <String>[];
    await _commit();
    return alerts;
  }

  // ---- Alerts (each one is shown once per month) ----
  List<String> _checkAlerts(Expense e) {
    final out = <String>[];
    final now = DateTime.now();
    if (!sameMonth(e.createdAt, now)) return out; // alerts are about the current month
    final fired = alerted.putIfAbsent(monthKey(now), () => <String>[]);
    void add(String msg) {
      out.add(msg);
      alertLog.insert(0, AlertEntry(msg, now));
      if (alertLog.length > 50) alertLog = alertLog.sublist(0, 50);
    }

    final c = catById(e.categoryId);
    final limit = c?.limit;
    if (catAlerts && c != null && c.notify && limit != null && limit > 0) {
      final spent = spentIn(c.id, now);
      final ratio = spent / limit;
      final level = alertLevelOf(c);
      final overKey = 'cat:${c.id}:over';
      final lvlKey = 'cat:${c.id}:$level';
      if (ratio >= 1) {
        if (crossAlertOf(c) && !fired.contains(overKey)) {
          add('${c.name} crossed its ${rupees(limit)} limit. Spent so far: ${rupees(spent)}.');
          fired
            ..add(overKey)
            ..add(lvlKey);
        }
      } else if (ratio >= level / 100 && !fired.contains(lvlKey)) {
        add('${c.name} has reached $level% of its limit: ${rupees(spent)} of ${rupees(limit)}.');
        fired.add(lvlKey);
      }
    }

    final budget = totalBudget;
    if (totalAlerts && budget > 0) {
      final tot = monthTotal;
      final ratio = tot / budget;
      final lvlKey = 'total:$defaultAlertAt';
      if (ratio >= 1) {
        if (defaultCross && !fired.contains('total:over')) {
          add('You crossed your total monthly budget of ${rupees(budget)}. Spent so far: ${rupees(tot)}.');
          fired
            ..add('total:over')
            ..add(lvlKey);
        }
      } else if (ratio >= defaultAlertAt / 100 && !fired.contains(lvlKey)) {
        add('${(ratio * 100).round()}% of your total monthly budget used: ${rupees(tot)} of ${rupees(budget)}.');
        fired.add(lvlKey);
      }
    }
    return out;
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
