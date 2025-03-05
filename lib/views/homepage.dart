import 'package:calibre_web_companion/view_models/homepage_view_model.dart';
import 'package:calibre_web_companion/view_models/login_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomepageViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Calibre Web Companion"),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.refresh_rounded),
            tooltip: "Refresh Library",
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.file_upload_rounded),
            tooltip: "Upload Book",
          ),
        ],
      ),
      body: Center(child: Text("Homepage")),
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
          label: "Search",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Me"),
      ],
      currentIndex: viewModel.currentNavIndex,
      onTap: (index) => viewModel.setCurrentNavIndex(index),
    );
  }
}
