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
}