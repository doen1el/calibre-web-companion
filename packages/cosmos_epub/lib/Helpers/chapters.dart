import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../Model/bookmark_model.dart';
import '../Model/chapter_model.dart';
import '../show_epub.dart';
import 'functions.dart';

/// Pops `true` when a chapter was chosen, or the [EpubBookmark] to jump to.
// ignore: must_be_immutable
class ChaptersList extends StatelessWidget {
  List<LocalChapterModel> chapters = [];
  final String bookId;
  final Widget? leadingIcon;
  final Color accentColor;
  final String chapterListTitle;

  /// Null hides the bookmarks tab.
  final List<EpubBookmark>? bookmarks;
  final EpubBookmarkLabels bookmarkLabels;
  final Future<List<EpubBookmark>> Function(String id)? onRemoveBookmark;

  ChaptersList(
      {super.key,
      required this.chapters,
      required this.bookId,
      this.leadingIcon,
      required this.accentColor,
      required this.chapterListTitle,
      this.bookmarks,
      this.bookmarkLabels = const EpubBookmarkLabels(),
      this.onRemoveBookmark});

  @override
  Widget build(BuildContext context) {
    // Detect text direction from chapter titles
    String allChapterText = chapters.map((c) => c.chapter).join(' ');
    TextDirection textDirection = RTLHelper.getTextDirection(allChapterText);

    final chapterList = Container(
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
                          if (context.mounted) Navigator.of(context).pop(true);
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
    );

    final closeButton = InkWell(
        onTap: () {
          Navigator.of(context).pop(false);
        },
        child: Icon(
          Icons.close,
          color: fontColor,
          size: 20.h,
        ));

    final bookmarkList = bookmarks;
    if (bookmarkList == null) {
      return Directionality(
        textDirection: textDirection,
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 40.h,
            backgroundColor: backColor,
            leading: closeButton,
          ),
          body: SafeArea(child: chapterList),
        ),
      );
    }

    return Directionality(
      textDirection: textDirection,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: backColor,
          appBar: AppBar(
            toolbarHeight: 40.h,
            backgroundColor: backColor,
            leading: closeButton,
            bottom: TabBar(
              labelColor: accentColor,
              unselectedLabelColor: fontColor,
              indicatorColor: accentColor,
              tabs: [
                Tab(text: bookmarkLabels.contents),
                Tab(text: bookmarkLabels.bookmarks),
              ],
            ),
          ),
          body: SafeArea(
            child: TabBarView(
              children: [
                chapterList,
                _BookmarkList(
                  initial: bookmarkList,
                  chapters: chapters,
                  accentColor: accentColor,
                  labels: bookmarkLabels,
                  onRemove: onRemoveBookmark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookmarkList extends StatefulWidget {
  final List<EpubBookmark> initial;
  final List<LocalChapterModel> chapters;
  final Color accentColor;
  final EpubBookmarkLabels labels;
  final Future<List<EpubBookmark>> Function(String id)? onRemove;

  const _BookmarkList({
    required this.initial,
    required this.chapters,
    required this.accentColor,
    required this.labels,
    required this.onRemove,
  });

  @override
  State<_BookmarkList> createState() => _BookmarkListState();
}

class _BookmarkListState extends State<_BookmarkList> {
  late List<EpubBookmark> _bookmarks = widget.initial;

  Future<void> _remove(EpubBookmark bookmark) async {
    setState(() => _bookmarks =
        _bookmarks.where((b) => b.id != bookmark.id).toList());
    final onRemove = widget.onRemove;
    if (onRemove == null) return;
    final updated = await onRemove(bookmark.id);
    if (mounted) setState(() => _bookmarks = updated);
  }

  @override
  Widget build(BuildContext context) {
    if (_bookmarks.isEmpty) {
      return Container(
        color: backColor,
        alignment: Alignment.center,
        padding: EdgeInsets.all(24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border,
                size: 40.h, color: fontColor.withValues(alpha: .5)),
            SizedBox(height: 12.h),
            Text(widget.labels.noBookmarks,
                textAlign: TextAlign.center,
                style: TextStyle(color: fontColor, fontSize: 15.sp)),
          ],
        ),
      );
    }

    return Container(
      color: backColor,
      child: ListView.separated(
        padding: EdgeInsets.all(10.h),
        itemCount: _bookmarks.length,
        separatorBuilder: (_, __) => Divider(height: 0, thickness: 1.h),
        itemBuilder: (context, i) {
          final bookmark = _bookmarks[i];
          final chapter = bookmark.chapterIndex >= 0 &&
                  bookmark.chapterIndex < widget.chapters.length
              ? widget.chapters[bookmark.chapterIndex].chapter
              : '';
          return Dismissible(
            key: ValueKey(bookmark.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red.withValues(alpha: .8),
              alignment: AlignmentDirectional.centerEnd,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            onDismissed: (_) => _remove(bookmark),
            child: ListTile(
              onTap: () => Navigator.of(context).pop(bookmark),
              leading: Icon(Icons.bookmark, color: widget.accentColor),
              title: Text(
                [
                  '${bookmark.percentage.round()}%',
                  if (chapter.isNotEmpty) chapter,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: fontColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600),
              ),
              subtitle: bookmark.excerpt.isEmpty
                  ? null
                  : Text(
                      bookmark.excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: fontColor.withValues(alpha: .7),
                          fontSize: 13.sp),
                    ),
              trailing: IconButton(
                tooltip: widget.labels.removeBookmark,
                icon: Icon(Icons.delete_outline,
                    color: fontColor.withValues(alpha: .6)),
                onPressed: () => _remove(bookmark),
              ),
            ),
          );
        },
      ),
    );
  }
}
