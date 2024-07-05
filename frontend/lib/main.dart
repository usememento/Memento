import 'package:flutter/material.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/pages/auth.dart';
import 'package:frontend/pages/main_page.dart';
import 'package:frontend/utils/translation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Translation.init();
  runApp(const Memento());
}

class Memento extends StatelessWidget {
  const Memento({super.key});

  static Map<String, Widget Function(BuildContext context)> routes = {
    '/': (context) => const MainPage(),
    '/login': (context) => const LoginPage(),
    '/register': (context) => const RegisterPage(),
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Memento",
      initialRoute: '/',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: App.mainColor)
            .copyWith(surface: Colors.white, primary: App.mainColor.shade600),
        fontFamily: App.isWindows ? "Microsoft YaHei" : null,
      ),
      navigatorKey: App.rootNavigatorKey ??= GlobalKey<NavigatorState>(),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
                seedColor: App.mainColor, brightness: Brightness.dark)
            .copyWith(surface: Colors.black, primary: App.mainColor.shade400),
        fontFamily: App.isWindows ? "Microsoft YaHei" : null,
      ),
      onGenerateRoute: (settings) {
        if (!appdata.isLogin &&
            settings.name != '/login' &&
            settings.name != '/register') {
          settings = const RouteSettings(name: '/login');
        }
        final builder = routes[settings.name] ?? (context) => const MainPage();
        return AppPageRoute(
            builder: builder, settings: settings, isRootRoute: true);
      },
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Text(details.exceptionAsString());
        };
        if (widget == null) throw "Widget is null!";
        return Material(
          color: context.colorScheme.surface,
          child: widget,
        );
      },
    );
  }
}
