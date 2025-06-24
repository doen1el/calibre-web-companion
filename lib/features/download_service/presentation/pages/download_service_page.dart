import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:calibre_web_companion/features/download_service/bloc/download_service_bloc.dart';
import 'package:calibre_web_companion/features/download_service/bloc/download_service_event.dart';
import 'package:calibre_web_companion/features/download_service/bloc/download_service_state.dart';

import 'package:calibre_web_companion/features/download_service/presentation/widgets/downloads_tab_widget.dart';
import 'package:calibre_web_companion/features/download_service/presentation/widgets/search_tab_widget.dart';

class DownloadServicePage extends StatefulWidget {
  const DownloadServicePage({super.key});

  @override
  State<DownloadServicePage> createState() => _DownloadServicePageState();
}

class _DownloadServicePageState extends State<DownloadServicePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DownloadServiceBloc>().add(GetDownloadStatus());
    });

    _tabController.addListener(() {
      if (_tabController.index == 1) {
        context.read<DownloadServiceBloc>().add(GetDownloadStatus());
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return BlocBuilder<DownloadServiceBloc, DownloadServiceState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(localizations.downloadService)),
          body: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: localizations.search),
                  Tab(
                    text:
                        '${localizations.downloads} ${_getDownloadsCount(state)}',
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [SearchTabWidget(), DownloadsTabWidget()],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getDownloadsCount(DownloadServiceState state) {
    final count = state.books.length;
    return count > 0 ? '($count)' : '';
  }
}
