import 'res.dart';
import 'models.dart';

export 'models.dart';
export 'res.dart';

class Network {
  static Network? instance;

  Network._internal();

  factory Network() => instance ??= Network._internal();

  Future<Res<User>> login(String username, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return const Res(User(
      avatar: "https://avatars.githubusercontent.com/u/67669799?v=4&size=64",
      name: "Testuser",
      token: "testuser_token",
    ));
  }

  Future<Res<User>> register(String username, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return const Res(User(
      avatar: "https://avatars.githubusercontent.com/u/67669799?v=4&size=64",
      name: "Testuser",
      token: "testuser_token",
    ));
  }
}