import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

MyUtils utils = MyUtils();

class MyUtils {
  void showSnackbar(BuildContext context, String msg) {
    final snackBar = SnackBar(
      duration: const Duration(seconds: 1),
      content: Text(msg),
      backgroundColor: Colors.blue,
      action: SnackBarAction(
        label: "Done",
        textColor: Colors.black,
        onPressed: () {},
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void showSnackbarMs(BuildContext context, int milliseconds, String msg) {
    final snackBar = SnackBar(
      duration: Duration(milliseconds: milliseconds),
      content: Text(msg),
      backgroundColor: Colors.blue,
      action: SnackBarAction(
        label: "Done",
        textColor: Colors.black,
        onPressed: () {},
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void showSnackbarError(BuildContext context, String msg) {
    final snackBar = SnackBar(
      duration: const Duration(seconds: 2),
      content: Text(msg),
      backgroundColor: Colors.red,
      action: SnackBarAction(
        label: "Done",
        textColor: Colors.red[400],
        onPressed: () {},
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void log(String msg) {
    if (kDebugMode) {
      debugPrint(msg);
    }
  }

  String listIntToString(List<int> list) {
    return utf8.decode(list);
  }

  List<Uint8List> stringToUint8ListList(String str) {
    List<int> list = utf8.encode(str);
    return List.from(list);
  }

  Uint8List stringToUint8List(String str) {
    final List<int> codeUnits = str.codeUnits;
    final Uint8List unit8List = Uint8List.fromList(codeUnits);

    return unit8List;
  }

  String uint8ListToString(Uint8List uint8list) {
    return String.fromCharCodes(uint8list);
  }

  String removeNullFromString(String str) {
    return str.replaceAll(RegExp('\\0'), '');
  }

  List<int> stringToListInt(String str) {
    List<int> list = utf8.encode(str);
    return list;
  }
  // String getStrFromListInt(List<int> buf, int start, int len) {
  //   String str = String.fromCharCodes(buf, start);

  //   for (String e in buf) {
  //     str += e.toString();
  //   }
  // }

  Divider divider({
    double thickness = 2.0,
    double height = 30.0,
    double indent = 10.0,
    double endIndent = 20.0,
    Color color = Colors.green,
  }) {
    // final thickness0 = thickness;
    // final height;
    // final indent;
    // final endIndent;
    // final color;

    return Divider(
      thickness: thickness,
      color: color,
      height: height,
      indent: indent,
      endIndent: endIndent,
    );
  }
}
