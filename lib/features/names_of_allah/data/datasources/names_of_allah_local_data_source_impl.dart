import 'dart:convert';

import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/names_of_allah/data/models/names_of_allah_model.dart';
import 'package:azkar_app/features/names_of_allah/data/datasources/names_of_allah_local_data_source.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';

class NamesOfAllahLocalDataSourceImpl extends NamesOfAllahLocalDataSource {
  @override
  Future<Either<Failure, List<NamesOfAllahModel>>> getNamesOfAllah() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/db/names_of_allah.json');
      List<dynamic> jsonData = json.decode(jsonString);
      List<NamesOfAllahModel> namesOfAllah =
          jsonData.map((json) => NamesOfAllahModel.fromJson(json)).toList();
      return Right(namesOfAllah);
    } catch (e) {
      return Left(JsonParsingFailure(
          'Failed to parse names of Allah JSON from assets: $e'));
    }
  }
}
