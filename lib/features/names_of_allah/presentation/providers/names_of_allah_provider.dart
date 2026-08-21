import 'package:azkar_app/core/enums/app_loading_status.dart';
import 'package:azkar_app/core/usecases/usecase.dart';
import 'package:azkar_app/features/names_of_allah/domain/entities/names_of_allah_entity.dart';
import 'package:azkar_app/features/names_of_allah/domain/usecases/get_names_of_allah_usecase.dart';
import 'package:flutter/material.dart';

class NamesOfAllahProvider extends ChangeNotifier {
  final GetNamesOfAllahUseCase getNamesOfAllahUseCase;
  NamesOfAllahProvider(
      {
      required this.getNamesOfAllahUseCase,
    });


  List<NamesOfAllahEntity> _namesOfAllahList = [];
  AppLoadingStatus _namesOfAllahStatus = AppLoadingStatus.initial;
  String? _namesOfAllahErrorMessage;
  List<NamesOfAllahEntity> get namesOfAllahList => _namesOfAllahList;
  AppLoadingStatus get namesOfAllahStatus => _namesOfAllahStatus;
  String? get namesOfAllahErrorMessage => _namesOfAllahErrorMessage;

  Future<void> loadNamesOfAllah() async {
    if (_namesOfAllahStatus == AppLoadingStatus.loading) {
      return;
    }
    _namesOfAllahStatus = AppLoadingStatus.loading;
    _namesOfAllahErrorMessage = null;
    notifyListeners();
    final result = await getNamesOfAllahUseCase(const NoParams());
    result.fold((failure) {
      _namesOfAllahStatus = AppLoadingStatus.error;
      _namesOfAllahErrorMessage = failure.message;
      _namesOfAllahList = [];
      notifyListeners();
    }, (namesOfAllahList) {
      _namesOfAllahStatus = AppLoadingStatus.loaded;
      _namesOfAllahList = namesOfAllahList;
      notifyListeners();
    });
  }
}
