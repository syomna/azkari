import 'dart:convert';

import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/azkar/data/datasources/azkar_local_data_source.dart';
import 'package:azkar_app/features/azkar/data/models/azkar_model.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';

class AzkarLocalDataSourceImpl extends AzkarLocalDataSource {
  @override
  Future<Either<Failure, List<AzkarModel>>> getAzkar() async {
    try {
      final jsonString = await rootBundle.loadString('assets/db/azkar.json');
      List<dynamic> jsonData = json.decode(jsonString);
      List<AzkarModel> azkarList =
          jsonData.map((json) => AzkarModel.fromJson(json)).toList();
      return Right(azkarList);
    } catch (e) {
      return Left(
          JsonParsingFailure('Failed to parse azkar JSON from assets: $e'));
    }
  }
}
