import 'package:flutter/material.dart';

class HomepageViewModel extends ChangeNotifier {
  int currentNavIndex = 0;

  /// Set the current navigation index
  ///
  /// Parameters:
  ///
  /// - `index`: int
  void setCurrentNavIndex(int index) {
    currentNavIndex = index;
    notifyListeners();
  }
}
