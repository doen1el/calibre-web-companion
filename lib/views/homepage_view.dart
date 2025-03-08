import 'package:calibre_web_companion/view_models/homepage_view_model.dart';
import 'package:calibre_web_companion/views/books_view.dart';
import 'package:calibre_web_companion/views/me_view.dart';
import 'package:calibre_web_companion/views/discover_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomepageView extends StatelessWidget {
  const HomepageView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomepageViewModel>();
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: [BooksView(), DiscoverView(), MeView()][viewModel.currentNavIndex],
      bottomNavigationBar: _buildBottomNavigation(
        context,
        localizations,
        viewModel,
      ),
    );
  }

  Widget _buildBottomNavigation(
    BuildContext context,
    AppLocalizations localizations,
    HomepageViewModel viewModel,
  ) {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.book_rounded),
          label: localizations.books,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_rounded),
          label: localizations.discover,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: localizations.me,
        ),
      ],
      currentIndex: viewModel.currentNavIndex,
      onTap: (index) => viewModel.setCurrentNavIndex(index),
    );
  }
}
