import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Helpers {
  static copyText(String text) {
    FlutterClipboard.copy(text).then((value) {
      Fluttertoast.showToast(
          msg: "تم النسخ",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 12.0);
    });
  }
}
