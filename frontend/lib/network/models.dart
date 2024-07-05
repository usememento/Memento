class Account {
  final String avatar;

  final String nickname;

  final String username;

  final String token;

  const Account(
      {required this.avatar,
      required this.nickname,
      required this.token,
      required this.username});
}

class User {
  final String username;

  final String nickname;

  final String avatar;

  final int follows;

  const User(
      {required this.avatar,
      required this.nickname,
      required this.username,
      required this.follows});
}

class Memo {
  final int id;

  final String content;

  final DateTime date;

  final User? author;

  int linksCount;

  final int repliesCount;

  bool isLiked;

  Memo(
      {required this.id,
      required this.content,
      required this.date,
      required this.author,
      required this.linksCount,
      required this.isLiked,
      required this.repliesCount});
}

class MemoList {
  final List<Memo> memos;

  final int pageCount;

  const MemoList({required this.memos, required this.pageCount});
}
