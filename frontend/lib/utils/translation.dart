import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

extension Translation on String {
  static var words = <String>{};
  String get tl {
    if(Translation.translation[this] == null) {
      var value = words.add(this);
      if (value) {
        var json = <String, String>{};
        for (var word in words) {
          json[word] = "";
        }
        File("D://translation.json").writeAsStringSync(
            const JsonEncoder.withIndent("  ").convert(json));
      }
    }
    return Translation.translation[this] ?? this;
  }

  String tlParams(List<Object> params) {
    var result = tl;
    for(var i = 0; i < params.length; i++) {
      result = result.replaceAll('{$i}', params[i].toString());
    }
    return result;
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