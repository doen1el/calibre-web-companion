import 'package:calibre_web_companion/views/book_list.dart';
import 'package:calibre_web_companion/views/widgets/long_button.dart';
import 'package:flutter/material.dart';

class DiscoverView extends StatelessWidget {
  const DiscoverView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 30),
            _buildSectionHeader(context, 'Discover'),
            _buildDiscoverWidget(context),
            _buildSectionHeader(context, 'Categories'),
            _buildCategoryWidget(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverWidget(BuildContext context) {
    return Column(
      children: [
        LongButton(
          text: 'Discover',
          icon: Icons.search,
          onPressed:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => BookList(
                        title: 'Discover Books',
                        bookListType: BookListType.discover,
                      ),
                ),
              ),
        ),
        LongButton(
          text: 'Show hot books',
          icon: Icons.local_fire_department_rounded,
          onPressed:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => BookList(
                        title: 'Hot Books',
                        bookListType: BookListType.hot,
                      ),
                ),
              ),
        ),
        LongButton(
          text: 'Show new books',
          icon: Icons.new_releases_rounded,
          onPressed:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => BookList(
                        title: 'New Books',
                        bookListType: BookListType.newlyAdded,
                      ),
                ),
              ),
        ),
        LongButton(
          text: 'Show rated books',
          icon: Icons.star_border_rounded,
          onPressed:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => BookList(
                        title: 'Rated Books',
                        bookListType: BookListType.rated,
                      ),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildCategoryWidget(BuildContext context) {
    return Column(
      children: [
        LongButton(
          text: 'Show authors',
          icon: Icons.people_rounded,
          onPressed:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => BookList(
                        title: 'Authors',
                        categoryType: CategoryType.author,
                      ),
                ),
              ),
        ),
        LongButton(
          text: 'Show categories',
          icon: Icons.category_rounded,
          onPressed:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => BookList(
                        title: 'Categories',
                        categoryType: CategoryType.category,
                      ),
                ),
              ),
        ),
        LongButton(
          text: 'Show  series',
          icon: Icons.library_books_rounded,
          onPressed:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => BookList(
                        title: 'Series',
                        categoryType: CategoryType.series,
                      ),
                ),
              ),
        ),
        LongButton(
          text: 'Show formats',
          icon: Icons.file_open_rounded,
          onPressed:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => BookList(
                        title: 'Formats',
                        categoryType: CategoryType.formats,
                      ),
                ),
              ),
        ),
        LongButton(
          text: 'Show languages',
          icon: Icons.language_rounded,
          onPressed:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => BookList(
                        title: 'Languages',
                        categoryType: CategoryType.language,
                      ),
                ),
              ),
        ),
        LongButton(
          text: 'Show publishers',
          icon: Icons.business_rounded,
          onPressed:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => BookList(
                        title: 'Publisher',
                        categoryType: CategoryType.publisher,
                      ),
                ),
              ),
        ),
        LongButton(
          text: 'Show ratings',
          icon: Icons.star_rounded,
          onPressed:
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => BookList(
                        title: 'Ratings',
                        categoryType: CategoryType.ratings,
                      ),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Divider(
            color: Theme.of(context).colorScheme.primaryContainer,
            thickness: 2,
          ),
        ],
      ),
    );
  }
}
