import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_bloc.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_event.dart';
import 'package:calibre_web_companion/features/book_view/bloc/book_view_state.dart';

class BookViewModeSelector extends StatelessWidget {
  const BookViewModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return BlocBuilder<BookViewBloc, BookViewState>(
      buildWhen:
          (previous, current) =>
              previous.isListView != current.isListView ||
              previous.columnCount != current.columnCount,
      builder: (context, state) {
        final scheme = Theme.of(context).colorScheme;
        return PopupMenuButton<dynamic>(
          icon: Icon(
            state.isListView
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded,
          ),
          tooltip: localizations.columnsCount,
          onSelected: (dynamic value) {
            if (value == 'list') {
              context.read<BookViewBloc>().add(const SetViewMode(true));
            } else if (value is int) {
              context.read<BookViewBloc>().add(ChangeColumnCount(value));
            }
          },
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 'list',
                  child: Row(
                    children: [
                      Icon(
                        Icons.view_list,
                        color: state.isListView ? scheme.primary : null,
                      ),
                      const SizedBox(width: 8),
                      Text(localizations.listView),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                for (int i = 1; i <= 5; i++)
                  PopupMenuItem<int>(
                    value: i,
                    child: Row(
                      children: [
                        Icon(
                          i == 1
                              ? Icons.looks_one
                              : i == 2
                              ? Icons.looks_two
                              : i == 3
                              ? Icons.looks_3
                              : i == 4
                              ? Icons.looks_4
                              : Icons.looks_5,
                          color:
                              !state.isListView && state.columnCount == i
                                  ? scheme.primary
                                  : null,
                        ),
                        const SizedBox(width: 8),
                        Text('$i ${localizations.columns}'),
                      ],
                    ),
                  ),
              ],
        );
      },
    );
  }
}
