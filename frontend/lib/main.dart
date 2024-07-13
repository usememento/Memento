import 'package:flutter/material.dart';
import 'package:frontend/components/overlay.dart';
import 'package:frontend/components/window_border.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/pages/auth.dart';
import 'package:frontend/pages/main_page.dart';
import 'package:frontend/utils/translation.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Translation.init();
  await appdata.readData();
  await App.init();
  if (App.isDesktop) {
    await WindowManager.instance.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: App.isMacOS,
      );
      if (App.isLinux) {
        // https://github.com/leanflutter/window_manager/issues/460
        return;
      }
      await windowManager.setMinimumSize(const Size(500, 600));
      await windowManager.show();
    });
  }
  runApp(const Memento());
}

class Memento extends StatefulWidget {
  const Memento({super.key});

  static Map<String, Widget Function(BuildContext context)> routes = {
    '/login': (context) => const LoginPage(),
    '/register': (context) => const RegisterPage(),
  };

  @override
  State<Memento> createState() => MementoState();
}

class MementoState extends State<Memento> {
  void forceRebuild() {}

  @override
  void initState() {
    App.initialRoute = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    App.rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Memento",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: App.mainColor)
            .copyWith(surface: Colors.white, primary: App.mainColor.shade600),
        fontFamily: App.isWindows ? "Microsoft YaHei" : null,
      ),
      navigatorKey: App.rootNavigatorKey!,
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
                seedColor: App.mainColor, brightness: Brightness.dark)
            .copyWith(surface: Colors.black, primary: App.mainColor.shade400),
        fontFamily: App.isWindows ? "Microsoft YaHei" : null,
      ),
      themeMode: switch (appdata.settings['theme_mode']) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system
      },
      onGenerateRoute: (settings) {
        var builder = Memento.routes[settings.name];
        String? name = settings.name;
        if(builder == null) {
          builder = (context) => const MainPage();
          name = null;
        }
        return AppPageRoute(
            builder: builder, settings: RouteSettings(name: name), isRootRoute: true);
      },
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Text(details.exceptionAsString());
        };
        if (widget == null) throw "Widget is null!";
        return Material(
          color: context.colorScheme.surface,
          child: OverlayWidget(WindowBorder(
            child: widget,
          )),
        );
      },
    );
  }
}
