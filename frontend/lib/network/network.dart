import 'res.dart';
import 'models.dart';

export 'models.dart';
export 'res.dart';

class Network {
  static Network? instance;

  Network._internal();

  factory Network() => instance ??= Network._internal();

  Future<Res<Account>> login(String username, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return const Res(Account(
      avatar: "https://avatars.githubusercontent.com/u/67669799?v=4&size=64",
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
