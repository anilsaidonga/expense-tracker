const kMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

const kConfirmed = 'confirmed';
const kFailed = 'failed';
const kPending = 'pending';
const kOtherId = 'other';
const kMethods = ['Cash', 'Card', 'UPI', 'Other'];

/// Indian digit grouping, e.g. 1234567 -> ₹12,34,567
String rupees(num v) {
  final n = v.round();
  final s = n.abs().toString();
  String out;
  if (s.length <= 3) {
    out = s;
  } else {
    final last3 = s.substring(s.length - 3);
    var rest = s.substring(0, s.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    out = '${parts.join(',')},$last3';
  }
  return '${n < 0 ? '-' : ''}₹$out';
}

String monthLabel(DateTime d) => '${kMonths[d.month - 1]} ${d.year}';
bool sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;
String monthKey(DateTime d) => '${d.year}-${d.month}';

String timeLabel(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour >= 12 ? 'PM' : 'AM'}';
}

String dateLabel(DateTime d) {
  final n = DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return '${d.day} ${kMonths[d.month - 1].substring(0, 3)}';
}

class Category {
  final String id;
  final String name;
  final bool isCustom;
  final double? limit; // null = no limit
  final bool notify;
  final int? alertAt; // null = use the default in Notifications
  final bool? alertOnCross; // null = use the default in Notifications

  const Category({
    required this.id,
    required this.name,
    this.isCustom = false,
    this.limit,
    this.notify = true,
    this.alertAt,
    this.alertOnCross,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isCustom': isCustom,
        'limit': limit,
        'notify': notify,
        'alertAt': alertAt,
        'alertOnCross': alertOnCross,
      };

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as String,
        name: j['name'] as String,
        isCustom: (j['isCustom'] as bool?) ?? false,
        limit: (j['limit'] as num?)?.toDouble(),
        notify: (j['notify'] as bool?) ?? true,
        alertAt: (j['alertAt'] as num?)?.toInt(),
        alertOnCross: j['alertOnCross'] as bool?,
      );
}

List<Category> defaultCategories() => const [
      Category(id: 'food', name: 'Food & Dining'),
      Category(id: 'travel', name: 'Fuel & Travel'),
      Category(id: 'shopping', name: 'Shopping'),
      Category(id: 'bills', name: 'Bills & Utilities'),
      Category(id: kOtherId, name: 'Others'),
    ];

class Expense {
  final String id;
  final double amount;
  final String categoryId;
  final String payee;
  final String upiId;
  final String upiApp;
  final String method; // Cash | Card | UPI | Other
  final String note;
  final String status; // confirmed | failed | pending
  final DateTime createdAt; // date AND time of the transaction

  const Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.payee,
    required this.upiId,
    required this.upiApp,
    required this.method,
    required this.note,
    required this.status,
    required this.createdAt,
  });

  Expense copyWith({String? status, String? categoryId}) => Expense(
        id: id,
        amount: amount,
        categoryId: categoryId ?? this.categoryId,
        payee: payee,
        upiId: upiId,
        upiApp: upiApp,
        method: method,
        note: note,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'categoryId': categoryId,
        'payee': payee,
        'upiId': upiId,
        'upiApp': upiApp,
        'method': method,
        'note': note,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> j) {
    final app = (j['upiApp'] as String?) ?? '';
    return Expense(
      id: j['id'] as String,
      amount: (j['amount'] as num).toDouble(),
      categoryId: j['categoryId'] as String,
      payee: (j['payee'] as String?) ?? '',
      upiId: (j['upiId'] as String?) ?? '',
      upiApp: app,
      method: (j['method'] as String?) ?? (app.isEmpty ? 'Cash' : 'UPI'),
      note: (j['note'] as String?) ?? '',
      status: (j['status'] as String?) ?? kConfirmed,
      createdAt: DateTime.parse(j['createdAt'] as String),
    );
  }
}

class AlertEntry {
  final String message;
  final DateTime at;
  const AlertEntry(this.message, this.at);
  Map<String, dynamic> toJson() => {'message': message, 'at': at.toIso8601String()};
  factory AlertEntry.fromJson(Map<String, dynamic> j) =>
      AlertEntry(j['message'] as String, DateTime.parse(j['at'] as String));
}

/// Details read from a UPI link or typed by the user before the payment screen.
class Draft {
  final String payee;
  final String upiId;
  final double? amount;
  const Draft({this.payee = '', this.upiId = '', this.amount});
}

/// Reads upi://pay?pa=...&pn=...&am=... or a plain UPI ID like name@bank.
Draft parseUpi(String raw) {
  final t = raw.trim();
  if (t.toLowerCase().startsWith('upi://')) {
    final q = Uri.tryParse(t)?.queryParameters ?? const <String, String>{};
    return Draft(
      payee: q['pn'] ?? '',
      upiId: q['pa'] ?? '',
      amount: double.tryParse(q['am'] ?? ''),
    );
  }
  if (t.contains('@')) return Draft(upiId: t);
  return Draft(payee: t);
}

/// Keeps only the last 10 digits of a phone number.
String normMobile(String s) {
  final d = s.replaceAll(RegExp(r'[^0-9]'), '');
  return d.length > 10 ? d.substring(d.length - 10) : d;
}
