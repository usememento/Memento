class Account {
  final String avatar;

  final String nickname;

  final String username;

  final String bio;

  final int totalFollows;

  final int totalLikes;

  final String token;

  final String refreshToken;

  final bool isAdmin;

  const Account(
      {required this.avatar,
      required this.nickname,
      required this.token,
      required this.username,
      required this.bio,
      required this.totalFollows,
      required this.totalLikes,
      required this.refreshToken,
      required this.isAdmin});

  Account copyWith(
      {String? avatar,
      String? nickname,
      String? bio,
      int? totalFollows,
      int? totalLikes,
      String? token,
      bool? isAdmin,
      String? refreshToken}) {
    return Account(
        avatar: avatar ?? this.avatar,
        nickname: nickname ?? this.nickname,
        bio: bio ?? this.bio,
        totalFollows: totalFollows ?? this.totalFollows,
        totalLikes: totalLikes ?? this.totalLikes,
        token: token ?? this.token,
        refreshToken: refreshToken ?? this.refreshToken,
        username: username,
        isAdmin: isAdmin ?? this.isAdmin);
  }

/*
{
  "token": {
    "access_token": "ODNJOTK3YJYTYJC1YI0ZYZUWLTGZMZATNGI4NJRKNMYZNMI3",
    "expires_in": 7200,
    "refresh_token": "YTK0YTM4NDMTNJDMOC01YZIZLWJIOTYTNWJLNWVIMJLHNDG5",
    "token_type": "Bearer"
  },
  "user": {
    "Username": "nyne",
    "Nickname": "",
    "Bio": "",
    "TotalLiked": 0,
    "TotalComment": 0,
    "TotalPosts": 0,
    "RegisteredAt": "2024-07-06T20:46:27.8787585+08:00",
    "AvatarUrl": ""
  }
}
 */
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
        avatar: json['user']['Avatar'],
        bio: json['user']['Bio'],
        nickname: json['user']['Nickname'],
        username: json['user']['Username'],
        totalFollows: json['user']['TotalPosts'],
        totalLikes: json['user']['TotalLiked'],
        token: json['token']['access_token'],
        refreshToken: json['token']['refresh_token'],
        isAdmin: json['user']['IsAdmin']);
  }

  /*
{
  "token": {
    "access_token": "ODNJOTK3YJYTYJC1YI0ZYZUWLTGZMZATNGI4NJRKNMYZNMI3",
    "expires_in": 7200,
    "refresh_token": "YTK0YTM4NDMTNJDMOC01YZIZLWJIOTYTNWJLNWVIMJLHNDG5",
    "token_type": "Bearer"
  },
  "user": {
    "Username": "nyne",
    "Nickname": "",
    "Bio": "",
    "TotalLiked": 0,
    "TotalComment": 0,
    "TotalPosts": 0,
    "RegisteredAt": "2024-07-06T20:46:27.8787585+08:00",
    "AvatarUrl": ""
  }
}
 */
  Map<String, dynamic> toJson() {
    return {
      'user': {
        'Avatar': avatar,
        'Bio': bio,
        'Nickname': nickname,
        'Username': username,
        'TotalPosts': totalFollows,
        'TotalLiked': totalLikes,
        "IsAdmin": isAdmin
      },
      'token': {
        'access_token': token,
        'refresh_token': refreshToken,
      }
    };
  }
}

class User {
  final String username;

  final String nickname;

  final String avatar;

  final String bio;

  final DateTime createdAt;

  final int totalLiked;

  final int totalComment;

  final int totalPosts;

  final int totalFiles;

  bool isAdmin;

  int totalFollower;

  final int totalFollows;

  bool isFollowed;

  User(
      {required this.username,
      required this.nickname,
      required this.avatar,
      required this.bio,
      required this.createdAt,
      required this.totalLiked,
      required this.totalComment,
      required this.totalPosts,
      required this.totalFiles,
      required this.totalFollower,
      required this.totalFollows,
      required this.isFollowed,
      required this.isAdmin});

  /*
{
  "Username": "nyne",
  "Nickname": "nyne",
  "Bio": "",
  "TotalLiked": 0,
  "TotalComment": 2,
  "TotalPosts": 3,
  "TotalFiles": 15,
  "TotalFollower": 0,
  "TotalFollows": 0,
  "RegisteredAt": "2024-07-08T11:38:48.0618698+08:00",
  "AvatarUrl": "",
  "IsFollowed": false
}
   */
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
        username: json['Username'],
        nickname: json['Nickname'],
        avatar: json['Avatar'],
        bio: json['Bio'],
        createdAt: DateTime.parse(json['RegisteredAt']),
        totalLiked: json['TotalLiked'],
        totalComment: json['TotalComment'],
        totalPosts: json['TotalPosts'],
        totalFiles: json['TotalFiles'],
        totalFollower: json['TotalFollower'],
        totalFollows: json['TotalFollows'],
        isFollowed: json['IsFollowed'],
        isAdmin: json['IsAdmin']);
  }
}

class Memo {
  final int id;

  String content;

  final DateTime date;

  final User? author;

  int likesCount;

  final int repliesCount;

  bool isLiked;

  bool isPublic;

  Memo(
      {required this.id,
      required this.content,
      required this.date,
      required this.author,
      required this.likesCount,
      required this.isLiked,
      required this.repliesCount,
      required this.isPublic});

  /*
{
    "IsLiked": false,
    "IsPrivate": false,
    "PostID": 1,
    "User": {
      "Username": "nyne",
      "Nickname": "",
      "Bio": "",
      "TotalLiked": 0,
      "TotalComment": 0,
      "TotalPosts": 4,
      "TotalFiles": 0,
      "TotalFollower": 0,
      "TotalFollows": 0,
      "RegisteredAt": "2024-07-06T20:46:27.8787585+08:00",
      "AvatarUrl": ""
    },
    "TotalLiked": 0,
    "TotalComment": 0,
    "CreatedAt": "2024-07-06T22:02:36.4441026+08:00",
    "EditedAt": "2024-07-06T22:02:36.4441026+08:00",
    "Content": "111"
  }
   */
  factory Memo.fromJson(Map<String, dynamic> json) {
    return Memo(
        id: json['PostID'],
        content: json['Content'],
        date: DateTime.parse(json['CreatedAt']),
        author: User.fromJson(json['User']),
        likesCount: json['TotalLiked'],
        isLiked: json['IsLiked'],
        repliesCount: json['TotalComment'],
        isPublic: !json['IsPrivate']);
  }
}

class MemoList {
  final List<Memo> memos;

  final int pageCount;

  const MemoList({required this.memos, required this.pageCount});
}

class HeatMapData {
  /// dailyData: a map from date to the number of memos on that day.
  ///
  /// key: date in the format of "yyyy-mm-dd".
  final Map<String, int> dailyData;
  final int totalMemos;
  int get totalDays => dailyData.length;
  final int totalLikes;

  const HeatMapData(this.dailyData, this.totalMemos, this.totalLikes);
}

/*
{
      "CommentID": 1,
      "PostID": 1,
      "User": {
        "Username": "nyne",
        "Nickname": "nyne",
        "Bio": "",
        "TotalLiked": 0,
        "TotalComment": 2,
        "TotalPosts": 1,
        "TotalFiles": 0,
        "TotalFollower": 0,
        "TotalFollows": 0,
        "RegisteredAt": "2024-07-08T11:38:48.0618698+08:00",
        "AvatarUrl": ""
      },
      "CreatedAt": "2024-07-08T11:42:20.3796542+08:00",
      "EditedAt": "2024-07-08T11:42:20.3796542+08:00",
      "Content": "123",
      "Liked": 0,
      "IsLiked": false
    }
 */
class Comment {
  final int id;

  final int memoId;

  final User author;

  final DateTime date;

  final String content;

  bool isLiked;

  int likesCount;

  Comment(
      {required this.id,
      required this.memoId,
      required this.author,
      required this.date,
      required this.content,
      required this.isLiked,
      required this.likesCount});

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
        id: json['CommentID'],
        memoId: json['PostID'],
        author: User.fromJson(json['User']),
        date: DateTime.parse(json['CreatedAt']),
        content: json['Content'],
        isLiked: json['IsLiked'],
        likesCount: json['Liked']);
  }
}

class UserComment {
  final Comment comment;

  final Memo memo;

  UserComment({required this.comment, required this.memo});

  factory UserComment.fromJson(Map<String, dynamic> json) {
    return UserComment(
        comment: Comment.fromJson(json['Comment']),
        memo: Memo.fromJson(json['Post']));
  }
}

class ServerFile {
  final int id;

  final String name;

  final DateTime time;

  const ServerFile({required this.id, required this.name, required this.time});

  factory ServerFile.fromJson(Map<String, dynamic> json) {
    return ServerFile(
        id: json["ID"],
        name: json["Filename"],
        time: DateTime.parse(json['Time']));
  }
}

class Captcha {
  final String identifier;
  final String backgroundImage;
  final String sliderImage;

  const Captcha(
      {required this.identifier,
      required this.backgroundImage,
      required this.sliderImage});

  factory Captcha.fromJson(Map<String, dynamic> json) {
    return Captcha(
        identifier: json['identifier'],
        backgroundImage: json['bg'],
        sliderImage: json['slider']);
  }
}
