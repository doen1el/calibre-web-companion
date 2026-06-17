import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../Model/chapter_model.dart';
import '../show_epub.dart';
import 'functions.dart';

// ignore: must_be_immutable
class ChaptersList extends StatelessWidget {
  List<LocalChapterModel> chapters = [];
  final String bookId;
  final Widget? leadingIcon;
  final Color accentColor;
  final String chapterListTitle;

  ChaptersList(
      {super.key,
      required this.chapters,
      required this.bookId,
      this.leadingIcon,
      required this.accentColor,
      required this.chapterListTitle});

  @override
  Widget build(BuildContext context) {
    // Detect text direction from chapter titles
    String allChapterText = chapters.map((c) => c.chapter).join(' ');
    TextDirection textDirection = RTLHelper.getTextDirection(allChapterText);

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 40.h,
          backgroundColor: backColor,
          leading: InkWell(
              onTap: () {
                Navigator.of(context).pop(false);
              },
              child: Icon(
                Icons.close,
                color: fontColor,
                size: 20.h,
              )),
        ),
        body: SafeArea(
          child: Container(
            color: backColor,
            padding: EdgeInsets.all(10.h),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: SvgPicture.asset(
                    'assets/ornament.svg',
                    package: 'cosmos_epub',
                    height: 20.h,
                    colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                itemCount: chapters.length,
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, i) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        onTap: () async {
                          await bookProgress.setCurrentChapterIndex(bookId, i);
                          Navigator.of(context).pop(true);
                        },
                        leading: leadingIcon,
                        minLeadingWidth: 20.w,
                        title: Padding(
                          padding: EdgeInsets.only(
                              left: textDirection == TextDirection.ltr
                                  ? chapters[i].depth * 15.w
                                  : 0,
                              right: textDirection == TextDirection.rtl
                                  ? chapters[i].depth * 15.w
                                  : 0),
                          child: Text(chapters[i].chapter,
                              textDirection: RTLHelper.getTextDirection(
                                  chapters[i].chapter),
                              style: TextStyle(
                                  color: bookProgress
                                              .getBookProgress(bookId)
                                              .currentChapterIndex ==
                                          i
                                      ? accentColor
                                      : fontColor,
                                  fontFamily: fontNames
                                      .where(
                                          (element) => element == selectedFont)
                                      .first,
                                  package: 'cosmos_epub',
                                  fontSize: 15.sp,
                                  fontWeight: chapters[i].depth == 0
                                      ? FontWeight.w600
                                      : FontWeight.w400)),
                        ),
                        dense: true,
                      ),
                      Divider(height: 0, thickness: 1.h),
                    ],
                  );
                }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
