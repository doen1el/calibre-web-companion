import 'package:calibre_web_companion/view_models/shelf_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ShelfDetailsView extends StatefulWidget {
  final String shelfId;
  const ShelfDetailsView({super.key, required this.shelfId});

  @override
  ShelfDetailsViewState createState() => ShelfDetailsViewState();
}

class ShelfDetailsViewState extends State<ShelfDetailsView> {
  @override
  void initState() {
    super.initState();
    // Load shelf details when the widget is initialized
    final viewModel = context.read<ShelfViewModel>();
    viewModel.getShelf(widget.shelfId);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ShelfViewModel>();

    return Scaffold(appBar: AppBar(title: Text("Shelf x")));
  }
}
