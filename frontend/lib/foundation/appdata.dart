import 'dart:convert';

import 'package:frontend/foundation/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/network.dart';

class _Appdata {
  Account? _user;

  Account get user => _user!;

  Account? get userOrNull => _user;

  bool get isLogin => _user != null;

  set user(Account user) {
    _user = user;
    saveData();
  }

  var settings = <String, dynamic>{
    "domain": '',
    'color': 'blue',
    'theme_mode': 'system',
    'default_memo_visibility': 'public'
  };

  String get domain {
    if(App.isWeb) {
      var domain = Uri.base.toString();
      if(domain.endsWith('/')) {
        domain = domain.substring(0, domain.length - 1);
      }
      return domain;
    } else {
      return settings['domain'];
    }
  }

  Future<void> saveData() async {
    var instance = await SharedPreferences.getInstance();
    await instance.setString('user', jsonEncode(_user?.toJson()));
    await instance.setString('settings', jsonEncode(settings));
  }

  Future<void> readData() async {
    var instance = await SharedPreferences.getInstance();
    var userString = instance.getString('user');
    if (userString != null) {
      var json = jsonDecode(userString);
      if (json != null) _user = Account.fromJson(json);
    }
    var settingsString = instance.getString('settings');
    if (settingsString != null) {
      var oldSettings = jsonDecode(settingsString);
      for (var key in oldSettings.keys) {
        settings[key] = oldSettings[key];
      }
    }
  }

  void logout() {
    _user = null;
    saveData();
  }
}

final appdata = _Appdata();
