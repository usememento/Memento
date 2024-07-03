import '../network/models.dart';

class _Appdata {
  User? _user;

  User get user => _user!;

  bool get isLogin => _user != null;

  void useTestUser() {
    _user = const User(
      avatar: "https://avatars.githubusercontent.com/u/67669799?v=4&size=64",
      name: "Testuser",
      token: "testuser_token",
    );
  }
}

final appdata = _Appdata();