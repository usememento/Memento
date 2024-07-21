import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/navigation_bar.dart';
import 'package:frontend/foundation/appdata.dart';

export "../utils/widget_utils.dart";
export 'page_route.dart';
export 'appdata.dart';


class _App {
  final version = "0.1.0";

  bool get isWeb => kIsWeb;
  bool get isAndroid => !isWeb && Platform.isAndroid;
  bool get isIOS => !isWeb && Platform.isIOS;
  bool get isWindows => !isWeb && Platform.isWindows;
  bool get isLinux => !isWeb && Platform.isLinux;
  bool get isMacOS => !isWeb && Platform.isMacOS;
  bool get isDesktop => isWindows || isLinux || isMacOS;
  bool get isMobile => isAndroid || isIOS;

  Locale get locale {
    return PlatformDispatcher.instance.locale;
  }

  NavigatorState? get navigator => observer?.navigator;

  NaviObserver? observer;

  GlobalKey<NavigatorState>? rootNavigatorKey;

  var mainColor = Colors.blue;

  var initialRoute = '/';

  Future<void> init() async {
    mainColor = switch(appdata.settings['color']) {
      'red' => Colors.red,
      'pink' => Colors.pink,
      'purple' => Colors.purple,
      'green' => Colors.green,
      'orange' => Colors.orange,
      'blue' => Colors.blue,
      _ => Colors.blue,
    };
  }
}

// ignore: non_constant_identifier_names
final App = _App();
