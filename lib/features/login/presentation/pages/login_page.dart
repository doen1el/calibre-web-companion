import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:calibre_web_companion/features/login/bloc/login_bloc.dart';
import 'package:calibre_web_companion/features/login/bloc/login_state.dart';
import 'package:calibre_web_companion/features/login/bloc/login_event.dart';

import 'package:calibre_web_companion/features/login/presentation/widgets/web_view_login_page.dart';
import 'package:calibre_web_companion/features/homepage/presentation/pages/home_page.dart';
import 'package:calibre_web_companion/core/services/snackbar.dart';
import 'package:calibre_web_companion/l10n/app_localizations.dart';
import 'package:calibre_web_companion/features/login/presentation/widgets/login_form_widget.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.login)),
      body: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state.status == LoginStatus.success) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          }

          if (state.status == LoginStatus.redirect &&
              state.redirectUrl != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => WebViewLoginPage(
                      redirectUrl: state.redirectUrl!,
                      baseUrl: state.url,
                    ),
              ),
            );
            context.read<LoginBloc>().add(const ResetLoginStatus());
          }

          if (state.status == LoginStatus.failure &&
              state.errorMessage != null) {
            context.showSnackBar(state.errorMessage!, isError: true);
          }
        },
        child: const Center(child: SingleChildScrollView(child: LoginForm())),
      ),
    );
  }
}
