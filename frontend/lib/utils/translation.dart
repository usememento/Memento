import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

extension Translation on String {
  String get tl {
    return Translation.translation[this] ?? this;
  }

  static Map<String, String> translation = {};

  static Future<void> init() async{
    var locale = PlatformDispatcher.instance.locale;
    var language = locale.languageCode;
    var country = locale.countryCode;
    if(language == 'en') {
      return;
    }
    String fileName;
    if(country != null) {
      fileName = "assets/translations/${language}_$country.json";
    } else {
      fileName = "assets/translations/$language.json";
    }
    try {
      var data = await rootBundle.load(fileName);
      var jsonString = utf8.decode(data.buffer.asUint8List());
      translation = Map.from(json.decode(jsonString));
    }
    catch(e) {
      debugPrint("Failed to load translation file: $fileName\n$e");
    }
  }
}