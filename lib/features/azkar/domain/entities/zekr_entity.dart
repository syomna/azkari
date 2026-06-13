import 'package:equatable/equatable.dart';

class ZekrEntity extends Equatable {
  final String category;
  final String count;
  final String description;
  final String reference;
  final String zekr;

  const ZekrEntity(
      {required this.category,
      required this.count,
      required this.description,
      required this.reference,
      required this.zekr});

  @override
  List<Object?> get props => [category, count, description, reference, zekr];
}
