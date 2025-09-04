class Receipt {
  final String title;
  final double value;
  final DateTime date;

  Receipt({
    required this.title,
    required this.value,
    required this.date,
  });

  bool get isFuture => date.isAfter(DateTime.now());
  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      title: map['title'],
      value: map['value'],
      date: DateTime.parse(map['date']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'value': value,
      'date': date.toIso8601String(),
    };
  }

}