import 'package:flutter/material.dart';
import 'package:frontend/foundation/page_route.dart';
import 'package:frontend/pages/home_page.dart';
import 'package:frontend/pages/page_404.dart';

void main() {
  runApp(const Memento());
}

class Memento extends StatelessWidget {
  const Memento({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Memento",
      initialRoute: '/',
      onUnknownRoute: (settings) => AppPageRoute(builder: (context) => const UnknownRoutePage()),
      routes: {
        '/': (context) => const HomePage()
      },
    );
  }
}
