import '../network/models.dart';

class _Appdata {
  User? _user;

  User get user => _user!;

  bool get isLogin => _user != null;

  set user(User user) {
    _user = user;
  }
}

final appdata = _Appdata();