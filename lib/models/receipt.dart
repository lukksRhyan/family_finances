class Receipt {
  final int? id;
  final String title;
  final double value;
  final DateTime date;

  Receipt({
    this.id,
    required this.title,
    required this.value,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'value': value,
      'date': date.toIso8601String(),
    };
  }

  static Receipt fromMap(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'],
      title: map['title'],
      value: map['value'],
      date: DateTime.parse(map['date']),
    );
  }
  bool get isFuture => date.isAfter(DateTime.now());

}