import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CustomToast {
  static void showToast(String text) {
    Fluttertoast.showToast(
      msg: text,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black38,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}

Snack(String msg, BuildContext ctx, Color color) {
  var snackBar = SnackBar(
      backgroundColor: color,
      content: Text(
        msg,
        textAlign: TextAlign.center,
      ));
  ScaffoldMessenger.of(ctx).showSnackBar(snackBar);
}