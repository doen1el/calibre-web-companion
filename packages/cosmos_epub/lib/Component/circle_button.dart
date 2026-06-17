import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../show_epub.dart';

// ignore: must_be_immutable
class CircleButton extends StatelessWidget {
  Color backColor, fontColor, accentColor;
  int id;

  CircleButton(
      {super.key,
      required this.accentColor,
      required this.backColor,
      required this.fontColor,
      required this.id});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(1.h),
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              width: 2.w,
              color: staticThemeId == id ? accentColor : Colors.grey)),
      child: Container(
        width: 35.w,
        height: 35.h,
        decoration: BoxDecoration(
          color: backColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            "T",
            style: TextStyle(color: fontColor),
          ),
        ),
      ),
    );
  }
}
