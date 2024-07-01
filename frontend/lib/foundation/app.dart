import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:frontend/components/frame.dart';

export "widget_utils.dart";
export 'page_route.dart';


class _App {
  final version = "1.0.0";

  bool get isAndroid => Platform.isAndroid;
  bool get isIOS => Platform.isIOS;
  bool get isWindows => Platform.isWindows;
  int? _windowsVersion;
  int get windowsVersion => _windowsVersion!;
  bool get isLinux => Platform.isLinux;
  bool get isMacOS => Platform.isMacOS;
  bool get isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  bool get isMobile => Platform.isAndroid || Platform.isIOS;

  Locale get locale {
    return PlatformDispatcher.instance.locale;
  }

  NavigatorState? get navigatorState => observer.navigator;

  var observer = NaviObserver();
}

// ignore: non_constant_identifier_names
final App = _App();
