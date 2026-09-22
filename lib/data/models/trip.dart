import 'dart:convert';

/// Categories used by the travel budget planner.
enum ExpenseCategory { food, transport, hotel, shopping, sightseeing, other }

extension ExpenseCategoryLabel on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.hotel:
        return 'Hotel';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.sightseeing:
        return 'Sightseeing';
      case ExpenseCategory.other:
        return 'Other';
    }
  }
}

/// A single spend recorded during a trip, stored in the local currency.
class Expense {
  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  final String id;
  String title;
  double amount;
  ExpenseCategory category;
  DateTime date;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'amount': amount,
        'category': category.name,
        'date': date.millisecondsSinceEpoch,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        amount: (json['amount'] as num).toDouble(),
        category: ExpenseCategory.values.firstWhere(
          (ExpenseCategory c) => c.name == json['category'],
          orElse: () => ExpenseCategory.other,
        ),
        date: DateTime.fromMillisecondsSinceEpoch(
            (json['date'] as num).toInt()),
      );
}

/// A trip: a budget in the home currency, spending in the local currency.
class Trip {
  Trip({
    required this.id,
    required this.name,
    required this.homeCurrency,
    required this.localCurrency,
    required this.budget,
    required this.startDate,
    required this.endDate,
    List<Expense>? expenses,
    this.completed = false,
  }) : expenses = expenses ?? <Expense>[];

  final String id;
  String name;
  String homeCurrency;
  String localCurrency;

  /// Budget expressed in [homeCurrency].
  double budget;
  DateTime startDate;
  DateTime endDate;
  List<Expense> expenses;
  bool completed;

  /// Total spent, in [localCurrency].
  double get spentLocal =>
      expenses.fold<double>(0, (double sum, Expense e) => sum + e.amount);

  Map<ExpenseCategory, double> get byCategory {
    final map = <ExpenseCategory, double>{};
    for (final Expense e in expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  int get days => endDate.difference(startDate).inDays + 1;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'homeCurrency': homeCurrency,
        'localCurrency': localCurrency,
        'budget': budget,
        'startDate': startDate.millisecondsSinceEpoch,
        'endDate': endDate.millisecondsSinceEpoch,
        'completed': completed,
        'expenses': expenses.map((Expense e) => e.toJson()).toList(),
      };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Trip',
        homeCurrency: json['homeCurrency'] as String? ?? 'USD',
        localCurrency: json['localCurrency'] as String? ?? 'EUR',
        budget: (json['budget'] as num?)?.toDouble() ?? 0,
        startDate: DateTime.fromMillisecondsSinceEpoch(
            (json['startDate'] as num).toInt()),
        endDate: DateTime.fromMillisecondsSinceEpoch(
            (json['endDate'] as num).toInt()),
        completed: json['completed'] as bool? ?? false,
        expenses: ((json['expenses'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic e) => Expense.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static String encodeList(List<Trip> items) =>
      jsonEncode(items.map((Trip t) => t.toJson()).toList());

  static List<Trip> decodeList(String? source) {
    if (source == null || source.isEmpty) return <Trip>[];
    try {
      final list = jsonDecode(source) as List<dynamic>;
      return list
          .map((dynamic e) => Trip.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <Trip>[];
    }
  }
}
