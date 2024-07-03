import 'package:flutter/material.dart';
import 'package:frontend/components/frame.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/pages/home_page.dart';
import 'package:frontend/pages/page_404.dart';
import 'package:frontend/utils/translation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Translation.init();
  runApp(const Memento());
}

class Memento extends StatelessWidget {
  const Memento({super.key});

  static Map<String, Widget Function(BuildContext context)> routes = {
    '/': (context) => const HomePage(),
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Memento",
      initialRoute: '/',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [App.observer],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: App.mainColor).copyWith(
          surface: Colors.white
        ),
        fontFamily: App.isWindows ? "Microsoft YaHei" : null,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: App.mainColor,
          brightness: Brightness.dark
        ).copyWith(
          surface: Colors.black
        ),
        fontFamily: App.isWindows ? "Microsoft YaHei" : null,
      ),
      onGenerateRoute: (settings) {
        final builder = routes[settings.name]
            ?? (context) => const UnknownRoutePage();
        return AppPageRoute(builder: builder, settings: settings);
      },
      builder: (context, widget) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Text(details.exceptionAsString());
        };
        if(widget == null)  throw "Widget is null!";
        return Overlay.wrap(child: Material(child: Frame(widget, App.observer),));
      },

    );
  }
}
