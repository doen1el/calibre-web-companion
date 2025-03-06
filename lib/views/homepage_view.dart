import 'package:calibre_web_companion/view_models/homepage_view_model.dart';
import 'package:calibre_web_companion/views/books_view.dart';
import 'package:calibre_web_companion/views/me_view.dart';
import 'package:calibre_web_companion/views/discover_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomepageView extends StatelessWidget {
  const HomepageView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomepageViewModel>();

    return Scaffold(
      body: [BooksView(), DiscoverView(), MeView()][viewModel.currentNavIndex],
      bottomNavigationBar: _buildBottomNavigation(context, viewModel),
    );
  }

  Widget _buildBottomNavigation(
    BuildContext context,
    HomepageViewModel viewModel,
  ) {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.book_rounded), label: "Books"),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_rounded),
          label: "Discover",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Me"),
      ],
      currentIndex: viewModel.currentNavIndex,
      onTap: (index) => viewModel.setCurrentNavIndex(index),
    );
  }
}
