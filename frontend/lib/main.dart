import 'package:flutter/material.dart';
import 'package:frontend/components/frame.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/pages/home_page.dart';
import 'package:frontend/pages/page_404.dart';

void main() {
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
