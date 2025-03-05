import 'package:flutter/material.dart';

class HomepageViewModel extends ChangeNotifier {
  int currentNavIndex = 0;

  void setCurrentNavIndex(int index) {
    currentNavIndex = index;
    notifyListeners();
  }
}
