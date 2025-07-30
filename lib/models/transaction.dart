import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class TransactionEntry extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  String description;

  @HiveField(2)
  double amount;

  TransactionEntry({
    required this.date,
    required this.description,
    required this.amount,
  });
}