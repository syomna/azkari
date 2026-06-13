import 'dart:convert';

import 'package:azkar_app/core/error/failures.dart';
import 'package:azkar_app/features/azkar/data/datasources/azkar_local_data_source.dart';
import 'package:azkar_app/features/azkar/data/datasources/sqflite/database_helper.dart';
import 'package:azkar_app/features/azkar/data/models/azkar_model.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';

class AzkarLocalDataSourceImpl extends AzkarLocalDataSource {
  final DatabaseHelper dbHelper;

  // Database helper injected through constructor to honor DI guidelines
  AzkarLocalDataSourceImpl({required this.dbHelper});

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

  @override
  Future<Either<Failure, List<AzkarModel>>> getCustomAzkar() async {
    try {
      final azkarList = await dbHelper.getCustomAzkar();
      return Right(azkarList);
    } catch (e) {
      return Left(
          DatabaseFailure('Failed to fetch custom azkar from SQLite: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveCustomAzkar(List<AzkarModel> items) async {
    try {
      await dbHelper.insertCustomAzkar(items);
      return const Right(unit); // unit is dartz's equivalent to void
    } catch (e) {
      return Left(DatabaseFailure('Failed to save custom azkar to SQLite: $e'));
    }
  }
  @override
  Future<void> deleteCustomCategory(String categoryName) async {
    await dbHelper.deleteCustomCategory(categoryName); 
  }
}
