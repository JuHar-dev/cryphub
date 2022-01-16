import 'package:after_layout/after_layout.dart';
import 'package:auto_route/auto_route.dart';
import 'package:cryphub/application/app_router.dart';
import 'package:cryphub/application/blocs/settings/settings_bloc.dart';
import 'package:cryphub/domain/core/cache/cache.dart';
import 'package:cryphub/domain/settings/settings_repository.dart';
import 'package:cryphub/themes.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:theme_provider/theme_provider.dart';

import '../../../configure_dependencies.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with AfterLayoutMixin<SplashScreen> {
  @override
  void afterFirstLayout(BuildContext context) {
    configureDependencies().then((value) async {
      final settings = await app.get<ISettingsRepository>().readSettings();
      ThemeProvider.controllerOf(context)
          .setTheme(settings.darkMode ? Themes.dark : Themes.light);
    });
    Future.wait([
      GetStorage.init(),
      Cache.init(),
    ]).then((_) async {
      AutoRouter.of(context).navigate(const HomeScreenRoute());
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
