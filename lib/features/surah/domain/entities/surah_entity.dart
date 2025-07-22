import 'package:equatable/equatable.dart';

class SurahEntity extends Equatable {
  final String name;
  final String surah;

  const SurahEntity({required this.name, required this.surah});
  
  @override
  List<Object?> get props => [name, surah];
}