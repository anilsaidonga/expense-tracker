import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models.dart';

void main() {
  test('rupees uses Indian digit grouping', () {
    expect(rupees(0), '₹0');
    expect(rupees(950), '₹950');
    expect(rupees(1234567), '₹12,34,567');
    expect(rupees(-1500), '-₹1,500');
  });

  test('parseUpi reads payee, UPI ID and amount from a upi:// link', () {
    final d = parseUpi('upi://pay?pa=shop@bank&pn=Sunrise%20Cafe&am=850');
    expect(d.upiId, 'shop@bank');
    expect(d.payee, 'Sunrise Cafe');
    expect(d.amount, 850);
  });

  test('parseUpi accepts a plain UPI ID', () {
    final d = parseUpi('ramesh@upi');
    expect(d.upiId, 'ramesh@upi');
    expect(d.amount, isNull);
  });

  test('Category keeps its limit and alert settings through JSON', () {
    const c = Category(id: 'x', name: 'Food', limit: 5000, alertAt: 75, alertOnCross: false);
    final back = Category.fromJson(c.toJson());
    expect(back.limit, 5000);
    expect(back.alertAt, 75);
    expect(back.alertOnCross, false);
    expect(back.notify, true);
  });
}
