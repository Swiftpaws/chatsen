import '/Consts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/Components/Notification.dart';
import 'BackgroundAudio/BackgroundAudioWrapper.dart';
import 'Pages/Home.dart';
import 'Settings/Settings.dart';
import 'Settings/SettingsState.dart';
import 'Theme/ThemeBloc.dart';
import 'Theme/ThemeManager.dart';
import 'Theme/ThemeState.dart';
import '/Components/UI/LoadingOverlay.dart';

/// Our [App] class. It represents our MaterialApp and will redirect us to our app's homepage.
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  Key globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) => BlocBuilder<Settings, SettingsState>(
        builder: (context, settingsState) => BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            final lightTheme = themeState is ThemeLoaded
                ? ThemeManager.buildTheme(
                    Brightness.light, themeState.colorScheme)
                : ThemeData.light();
            final darkTheme = themeState is ThemeLoaded
                ? ThemeManager.buildTheme(
                    Brightness.dark, themeState.colorScheme,
                    highContrast: themeState.highContrast)
                : ThemeData.dark();
            final themeMode =
                themeState is ThemeLoaded ? themeState.mode : ThemeMode.system;

            Widget home;

            if (themeState is ThemeLoaded && settingsState is SettingsLoaded) {
              home = NotificationWrapper(
                child: Builder(
                  builder: (context) => ThemeManager.routeWrapper(
                    context: context,
                    child: settingsState.notificationBackground &&
                            !kPlayStoreRelease
                        ? BackgroundAudioWrapper(
                            child: HomePage(key: globalKey),
                          )
                        : HomePage(key: globalKey),
                  ),
                ),
              );
            } else {
              home = const Scaffold(
                body: LoadingOverlay(status: "Starting up..."),
              );
            }

            return MaterialApp(
              darkTheme: darkTheme,
              theme: lightTheme,
              themeMode: themeMode,
              debugShowCheckedModeBanner: false,
              home: home,
            );
          },
        ),
      );
}
