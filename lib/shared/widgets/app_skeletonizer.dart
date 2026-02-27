import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:calibre_web_companion/features/settings/bloc/settings_bloc.dart';

class AppSkeletonizer extends StatelessWidget {
  final bool enabled;
  final Widget child;
  final PaintingEffect? effect;

  const AppSkeletonizer({
    super.key,
    required this.enabled,
    required this.child,
    this.effect,
  });

  @override
  Widget build(BuildContext context) {
    final isEInkMode = context.read<SettingsBloc>().state.isEInkMode;

    return Skeletonizer(
      enabled: enabled,
      effect: isEInkMode ? const SolidColorEffect() : effect,
      child: child,
    );
  }
}
