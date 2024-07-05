import '../network/models.dart';

class _Appdata {
  Account? _user;

  Account get user => _user!;

  bool get isLogin => _user != null;

  set user(Account user) {
    _user = user;
  }
}

final appdata = _Appdata();