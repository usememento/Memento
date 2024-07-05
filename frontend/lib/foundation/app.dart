import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

export "../utils/widget_utils.dart";
export 'page_route.dart';
export 'appdata.dart';


class _App {
  final version = "1.0.0";

  bool get isWeb => kIsWeb;
  bool get isAndroid => !isWeb && Platform.isAndroid;
  bool get isIOS => !isWeb && Platform.isIOS;
  bool get isWindows => !isWeb && Platform.isWindows;
  bool get isLinux => !isWeb && Platform.isLinux;
  bool get isMacOS => !isWeb && Platform.isMacOS;
  bool get isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  bool get isMobile => Platform.isAndroid || Platform.isIOS;

  Locale get locale {
    return PlatformDispatcher.instance.locale;
  }

  NavigatorState? get navigatorState => navigatorKey?.currentState;

  GlobalKey<NavigatorState>? navigatorKey;

  GlobalKey<NavigatorState>? rootNavigatorKey;

  final mainColor = Colors.blue;
}

// ignore: non_constant_identifier_names
final App = _App();
