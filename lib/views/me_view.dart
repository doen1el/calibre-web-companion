import 'package:calibre_web_companion/models/stats_model.dart';
import 'package:calibre_web_companion/view_models/me_view_model.dart';
import 'package:calibre_web_companion/views/login_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MeView extends StatelessWidget {
  const MeView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Me'),
        actions: [
          IconButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.remove("calibre_web_session");
              // ignore: use_build_context_synchronously
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginView()),
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => viewModel.getStats(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildStatsWidget(context, viewModel),
              // Add more sections here as needed
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsWidget(BuildContext context, MeViewModel viewModel) {
    if (viewModel.isLoading && viewModel.stats == null) {
      return const Center(heightFactor: 3, child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(
        heightFactor: 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading stats: ${viewModel.errorMessage}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.getStats(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    // Use stats or default empty model
    final stats = viewModel.stats ?? StatsModel();

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              'Library Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatRow(
                  context,
                  Icons.book,
                  'Books',
                  stats.books.toString(),
                ),
                const Divider(),
                _buildStatRow(
                  context,
                  Icons.person,
                  'Authors',
                  stats.authors.toString(),
                ),
                const Divider(),
                _buildStatRow(
                  context,
                  Icons.category,
                  'Categories',
                  stats.categories.toString(),
                ),
                const Divider(),
                _buildStatRow(
                  context,
                  Icons.collections_bookmark,
                  'Series',
                  stats.series.toString(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
