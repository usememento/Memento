import 'dart:convert';

import 'package:dio/dio.dart';

import 'res.dart';
import 'models.dart';

export 'models.dart';
export 'res.dart';

class Network {
  static Network? instance;
  static String serverAddr="http://localhost:1323";
  Network._internal();
  final dio=Dio();

  factory Network() => instance ??= Network._internal();

  Future<Res<Account>> login(String username, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    final queryData={
      "client_id":"000000",
      "client_secret":"999999",
      "grant_type":"password",
      "scope":"read"
    };
    final formData = FormData.fromMap(
      {
        "username": username,
        "password": password,
      },
    );
    final response=await dio.post("$serverAddr/user/login",queryParameters: queryData,data:formData);
    print(response);
    final user=await dio.get<Map<String,dynamic>>("$serverAddr/api/user/get",queryParameters: {"username":username});

    return const Res(Account(
      avatar: "$serverAddr/api/file/download?url=$user.ContentUrl",
      nickname: "Testuser",
      username: "testuser",
      token: "testuser_token",
    ));
  }

  Future<Res<Account>> register(String username, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return const Res(Account(
      avatar: "https://avatars.githubusercontent.com/u/67669799?v=4&size=64",
      nickname: "Testuser",
      username: "testuser",
      token: "testuser_token",
    ));
  }

  Future<Res<List<Memo>>> getHomePage(int page) async {
    await Future.delayed(const Duration(seconds: 1));
    return Res([
      Memo(
        id: 1,
        content: _testMemoContent,
        date: DateTime.parse("2024-07-03"),
        author: null,
        linksCount: 1,
        repliesCount: 1,
        isLiked: false,
      )
    ], subData: 1);
  }

  Future<Res<bool>> favoriteOrUnfavorite(int memoId) async {
    await Future.delayed(const Duration(seconds: 1));
    return const Res(true);
  }
}

const _testMemoContent = '''
# Hello

```dart
void main() {
  print("Hello world");
}
```

> 123

我喜欢玩 #原神

abcdef
ghijkl
''';
