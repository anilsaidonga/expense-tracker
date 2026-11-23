import 'package:expense_tracker/app_state.dart';
import 'package:expense_tracker/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

var _n = 0;
Expense exp(double amount, {String cat = 'food', DateTime? at, String status = kConfirmed}) =>
    Expense(
      id: 'e${_n++}',
      amount: amount,
      categoryId: cat,
      payee: '',
      upiId: '',
      upiApp: '',
      method: 'Cash',
      note: '',
      status: status,
      createdAt: at ?? DateTime.now(),
    );

Future<AppState> fresh() async {
  SharedPreferences.setMockInitialValues({});
  final s = AppState();
  await s.load();
  return s;
}

void main() {
  test('editing a category saves its limit and alert settings, and they persist', () async {
    final s = await fresh();
    await s.updateCategory('food',
        name: 'Food & Dining', limit: 5000, notify: true, alertAt: 75, cross: true);
    final c = s.catById('food')!;
    expect(c.limit, 5000);
    expect(s.alertLevelOf(c), 75);

    final again = AppState();
    await again.load();
    expect(again.catById('food')!.limit, 5000);
    expect(again.alertLevelOf(again.catById('food')!), 75);
  });

  test('total budget is the sum of the category limits', () async {
    final s = await fresh();
    await s.setLimits({'food': 1000, 'travel': 2000});
    expect(s.totalBudget, 3000);
    await s.setLimits({'food': null});
    expect(s.totalBudget, 2000);
  });

  test('an alert fires once at the chosen level and once when the limit is crossed', () async {
    final s = await fresh();
    await s.setNotificationSettings(total: false);
    await s.updateCategory('food',
        name: 'Food & Dining', limit: 1000, notify: true, alertAt: 75, cross: true);

    final a1 = await s.addExpense(exp(800));
    expect(a1.length, 1);
    expect(a1.first, contains('75%'));

    expect(await s.addExpense(exp(100)), isEmpty); // 900: already alerted at 75%

    final a3 = await s.addExpense(exp(200)); // 1100: crossed
    expect(a3.length, 1);
    expect(a3.first, contains('crossed'));

    expect(await s.addExpense(exp(10)), isEmpty);
  });

  test('a payment from an earlier month does not trigger alerts', () async {
    final s = await fresh();
    await s.updateCategory('bills',
        name: 'Bills & Utilities', limit: 100, notify: true, alertAt: 50, cross: true);
    final old = DateTime.now().subtract(const Duration(days: 40));
    expect(await s.addExpense(exp(500, cat: 'bills', at: old)), isEmpty);
  });

  test('failed and pending payments are not counted', () async {
    final s = await fresh();
    await s.addExpense(exp(100, status: kFailed));
    await s.addExpense(exp(200, status: kPending));
    await s.addExpense(exp(300));
    expect(s.monthTotal, 300);
  });

  test('deleting a category moves its expenses to Others', () async {
    final s = await fresh();
    final gym = await s.addCategory('Gym', limit: 500);
    await s.addExpense(exp(120, cat: gym.id));
    await s.deleteCategory(gym.id);
    expect(s.catById(gym.id), isNull);
    expect(s.expenses.first.categoryId, kOtherId);
  });

  test('adding a category with an existing name returns the existing one', () async {
    final s = await fresh();
    final before = s.categories.length;
    final c = await s.addCategory('food & dining');
    expect(c.id, 'food');
    expect(s.categories.length, before);
  });

  test('account: create profile, sign in, log out', () async {
    final s = await fresh();
    await s.createProfile(name: 'Asha Rao', mobileNumber: '9876543210', emailAddr: 'a@b.com');
    expect(s.loggedIn, false);
    await s.signIn();
    expect(s.loggedIn, true);
    expect(s.displayName, 'Asha');
    expect(s.formattedMobile, '+91 98765 43210');
    await s.logout();
    expect(s.loggedIn, false);
  });

  test('normMobile keeps the last 10 digits', () {
    expect(normMobile('+91 98765 43210'), '9876543210');
    expect(normMobile('98765-43210'), '9876543210');
  });
}
