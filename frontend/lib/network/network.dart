import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/utils/image.dart';

import '../foundation/appdata.dart';
import 'res.dart';
import 'models.dart';

export 'models.dart';
export 'res.dart';

class AppInterceptor extends Interceptor {
  static bool isWaitingRefreshingToken = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // setDebugProxy();
    var token = appdata.userOrNull?.token;
    if (token != null && token.isNotEmpty) {
      options.headers["Authorization"] = "Bearer $token";
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode != null) {
      if (err.response!.statusCode! < 500) {
        var errorMessage = err.message ?? "error";
        var data = err.response!.data;
        if (data is String) {
          try {
            var json = jsonDecode(data);
            if (json is Map) {
              var message = json['message'];
              if (message is String) {
                errorMessage = message;
              }
            }
          } catch (e) {
            errorMessage = "Invalid Response: $data";
          }
        } else if (data is Map && data['message'] != null) {
          var message = data['message'];
          errorMessage = message.toString();
        }
        handler.next(DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          error: errorMessage,
        ));
      } else {
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (response.statusCode == 401) {
      if (!appdata.isLogin) {
        handler.reject(DioException(
            error: "Not Login",
            requestOptions: response.requestOptions,
            response: response));
        return;
      }
      if (isWaitingRefreshingToken) {
        await Future.doWhile(() {
          return Future.delayed(const Duration(milliseconds: 100),
              () => isWaitingRefreshingToken);
        });
        response.requestOptions.headers["Authorization"] =
            "Bearer ${appdata.user.token}";
        Network().dio.fetch(response.requestOptions).then((value) {
          handler.resolve(value);
        });
        return;
      }
      isWaitingRefreshingToken = true;
      var res = await Network().refresh();
      isWaitingRefreshingToken = false;
      if (res.success) {
        appdata.user = res.data;
        response.requestOptions.headers["Authorization"] =
            "Bearer ${appdata.user.token}";
        Network().dio.fetch(response.requestOptions).then((value) {
          handler.resolve(value);
        });
      } else {
        handler.reject(DioException(
            error: "Refresh Token Failed",
            requestOptions: response.requestOptions,
            response: response));
      }
    } else {
      handler.next(response);
    }
  }
}

class Network {
  static Network? instance;

  Network._internal() {
    dio.interceptors.add(LogInterceptor());
    dio.interceptors.add(AppInterceptor());
    setBaseUrl();
  }

  factory Network() => instance ??= Network._internal();

  var dio = Dio(BaseOptions(
    contentType: Headers.formUrlEncodedContentType,
    validateStatus: (status) => status! < 300 || status == 401,
  ));

  void setBaseUrl() {
    var url = appdata.settings['domain'] as String;
    dio.options.baseUrl = url;
  }

  static const _authQuery = {
    'client_id': '000000',
    'client_secret': '999999',
    'grant_type': 'password',
  };

  Future<Res<Account>> refresh() async {
    try {
      var res =
          await dio.post<Map<String, dynamic>>("/api/user/refresh", data: {
        "refresh_token": appdata.user.refreshToken,
      }, queryParameters: {
        'client_id': '000000',
        'client_secret': '999999',
        'grant_type': 'refresh_token',
      });
      return Res(Account.fromJson(res.data!));
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<Account>> login(String username, String password) async {
    try {
      setBaseUrl();
      var res = await dio.post<Map<String, dynamic>>("/api/user/login",
          data: {
            "username": username,
            "password": password,
          },
          queryParameters: _authQuery);
      return Res(Account.fromJson(res.data!));
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<Account>> register(String username, String password) async {
    try {
      setBaseUrl();
      var res = await dio.post<Map<String, dynamic>>("/api/user/create",
          data: {
            "username": username,
            "password": password,
          },
          queryParameters: _authQuery);
      return Res(Account.fromJson(res.data!));
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<List<Memo>>> getMemosList(int page, [String? username]) async {
    try {
      page--;
      var res = await dio.get<Map>("/api/post/userPosts", queryParameters: {
        "page": page,
        "username": username ?? appdata.user.username
      });
      return Res(
          (res.data!["posts"] as List).map((e) => Memo.fromJson(e)).toList(),
          subData: res.data!['maxPage'] + 1);
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<List<Memo>>> getAllMemosList(int page) async {
    try {
      page--;
      var res = await dio.get<Map>("/api/post/all", queryParameters: {
        "page": page,
      });
      return Res(
          (res.data!["posts"] as List).map((e) => Memo.fromJson(e)).toList(),
          subData: res.data!['maxPage'] + 1);
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<List<Memo>>> getMemosListByTag(int page, String tag) async {
    try {
      page--;
      var res = await dio.get<Map>("/api/post/taggedPosts",
          queryParameters: {"page": page, "tag": "#$tag"});
      return Res(
          (res.data!["posts"] as List).map((e) => Memo.fromJson(e)).toList(),
          subData: res.data!['maxPage'] + 1);
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<Memo>> getMemoById(String id) async {
    try {
      var res = await dio.get<Map<String, dynamic>>("/api/post/get", queryParameters: {
        "id": id,
      });
      return Res(Memo.fromJson(res.data!));
    }
    catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<bool>> likeOrUnlike(int memoId, bool isLike) async {
    if (!appdata.isLogin) return const Res.error("Not Login");
    try {
      var res = await dio.post(isLike ? "/api/post/like" : "/api/post/unlike",
          data: {"id": memoId});
      if (res.statusCode == 200) {
        return const Res(true);
      } else {
        throw "Invalid Status Code ${res.statusCode}";
      }
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<bool>> postMemo(String content, bool isPublic) async {
    if (!appdata.isLogin) return const Res.error("Not Login");
    try {
      var res = await dio.post("/api/post/create",
          data: FormData.fromMap({
            "content": MultipartFile.fromString(content, filename: "1.md"),
            "permission": isPublic ? "public" : "private"
          }));
      return Res(res.statusCode == 200);
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<bool>> editMemo(String content, bool isPublic, int id) async {
    if (!appdata.isLogin) return const Res.error("Not Login");
    try {
      var res = await dio.post("/api/post/edit",
          data: FormData.fromMap({
            "content": MultipartFile.fromString(content, filename: "1.md"),
            "permission": isPublic ? "public" : "private",
            "id": id
          }));
      return Res(res.statusCode == 200);
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<HeatMapData>> getHeatMapData([String? username]) async {
    if (!appdata.isLogin) return const Res.error("Not Login");
    try {
      var res = await dio.get<Map<String, dynamic>>("/api/user/heatmap",
          queryParameters: {"username": username ?? appdata.user.username});
      return Res(HeatMapData(
          Map.from(res.data!['map']), res.data!['memos'], res.data!['likes']));
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<List<Comment>>> getComments(int memoId, int page) async {
    try {
      page--;
      var res = await dio.get<Map<String, dynamic>>("/api/comment/postComments",
          queryParameters: {
            "id": memoId,
            "page": page,
          });
      return Res(
          (res.data!["comments"] as List)
              .map((e) => Comment.fromJson(e))
              .toList(),
          subData: res.data!["maxPage"] + 1);
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<bool>> sendComment(int memoId, String content) async {
    if (!appdata.isLogin) return const Res.error("Not Login");
    try {
      var res = await dio.post("/api/comment/create", data: {
        "id": memoId,
        "content": content,
      });
      return Res(res.statusCode == 200);
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<bool>> likeOrUnlikeComment(int id, bool isLike) async {
    if (!appdata.isLogin) return const Res.error("Not Login");
    try {
      var res = await dio.post(
          isLike ? "/api/comment/like" : "/api/comment/unlike",
          data: {"id": id});
      if (res.statusCode == 200) {
        return const Res(true);
      } else {
        throw "Invalid Status Code ${res.statusCode}";
      }
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  /// yield [double] as progress if uploading, [String] as file ID if finished
  Stream<Object> uploadFile(
      List<int> data, String fileName, CancelToken cancelToken) {
    var controller = StreamController<Object>();
    () async {
      try {
        if (!appdata.isLogin) {
          controller.addError("Not Login");
          return;
        }
        var res = await dio.post<Map>("/api/file/upload",
            data: FormData.fromMap({
              "file": MultipartFile.fromBytes(data, filename: fileName),
            }),
            cancelToken: cancelToken, onSendProgress: (current, total) {
          controller.add(current / total);
        });

        if (res.statusCode != 200) {
          controller.addError("Invalid Status Code ${res.statusCode}");
        } else {
          controller.add(res.data!['ID'].toString());
        }
      } catch (e) {
        controller.addError(e);
      } finally {
        controller.close();
      }
    }();
    return controller.stream;
  }

  Future<Res<User>> getUserDetails(String userName) async {
    try {
      var res = await dio
          .get<Map<String, dynamic>>("/api/user/get", queryParameters: {
        "username": userName,
      });
      return Res(User.fromJson(res.data!));
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<bool>> followOrUnfollow(String userName, bool isFollow) async {
    if (!appdata.isLogin) return const Res.error("Not Login");
    try {
      var res = await dio
          .post(isFollow ? "/api/user/follow" : "/api/user/unfollow", data: {
        "followee": userName,
      });
      if (res.statusCode == 200) {
        return const Res(true);
      } else {
        throw "Invalid Status Code ${res.statusCode}";
      }
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<List<User>>> getFollowers(String userName, int page) async {
    try {
      page--;
      var res = await dio.get<Map>("/api/user/follower", queryParameters: {
        "username": userName,
        "page": page,
      });
      return Res(
          (res.data!["users"] as List).map((e) => User.fromJson(e)).toList(),
          subData: res.data!["maxPage"] + 1);
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<List<User>>> getFollowing(String userName, int page) async {
    try {
      page--;
      var res = await dio.get<Map>("/api/user/following", queryParameters: {
        "username": userName,
        "page": page,
      });
      return Res(
          (res.data!["users"] as List).map((e) => User.fromJson(e)).toList(),
          subData: res.data!["maxPage"] + 1);
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<User>> editProfile(
      {String? nickname,
      String? bio,
      Uint8List? avatar,
      String? avatarFileName}) async {
    if (!appdata.isLogin) return const Res.error("Not Login");
    try {
      String? ext;
      if (avatarFileName != null) {
        ext = avatarFileName.split('.').last;
      }
      if (avatar != null && avatar.length > 1024 * 1024) {
        (avatar, ext) =
            await compute((message) => resizeImage(avatar!, 256), null);
      }
      var res = await dio.post<Map<String, dynamic>>("/api/user/edit",
          data: FormData.fromMap({
            if (nickname != null) "nickname": nickname,
            if (bio != null) "bio": bio,
            if (avatar != null)
              "avatar":
                  MultipartFile.fromBytes(avatar, filename: "avatar.$ext"),
          }));
      return Res(User.fromJson(res.data!));
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<bool>> changePassword(
      {required String password,
      required String newPassword,
      required String confirmPassword}) async {
    if (!appdata.isLogin) return const Res.error("Not Login");
    if (newPassword != confirmPassword) {
      return const Res.error("Password not match");
    }

    try {
      var res = await dio.post("/api/user/changePwd", data: {
        "oldPassword": password,
        "newPassword": newPassword,
      });
      if (res.statusCode == 200) {
        return const Res(true);
      } else {
        throw "Invalid Status Code ${res.statusCode}";
      }
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<bool>> deleteMemo(int id) async {
    if (!appdata.isLogin) return const Res.error("Not Login");
    try {
      var res = await dio.delete("/api/post/delete/$id");
      if (res.statusCode == 200) {
        return const Res(true);
      } else {
        throw "Invalid Status Code ${res.statusCode}";
      }
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<List<UserComment>>> getUserComment(
      String username, int page) async {
    try {
      page--;
      var res =
          await dio.get<Map>("/api/comment/userComments", queryParameters: {
        "username": username,
        "page": page,
      });
      return Res(
          (res.data!["comments"] as List)
              .map((e) => UserComment.fromJson(e))
              .toList(),
          subData: res.data!["maxPage"] + 1);
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<List<Memo>>> search(String keyword, int page) async {
    try {
      page--;
      var res = await dio.get<Map>("/api/search/post", queryParameters: {
        "keyword": keyword,
        "page": page,
      });
      return Res(
          (res.data!["posts"] as List).map((e) => Memo.fromJson(e)).toList(),
          subData: res.data!["maxPage"] + 1);
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<List<Memo>>> getUserLikedMemos(String username, int page) async {
    try {
      page--;
      var res = await dio.get<Map>("/api/post/likedPosts", queryParameters: {
        "username": username,
        "page": page,
      });
      return Res(
          (res.data!["posts"] as List).map((e) => Memo.fromJson(e)).toList(),
          subData: res.data!["maxPage"] + 1);
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  /// type: "all" or "user"
  Future<Res<List<String>>> getTags(String type) async {
    try {
      var res = await dio.get<List>("/api/post/tags", queryParameters: {
        "type": type,
      });
      return Res((res.data as List).map((e) => e.toString()).toList());
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<List<ServerFile>>> getFileList(int page) async {
    try {
      page--;
      var res =
          await dio.get<Map>("/api/file/all", queryParameters: {"page": page});
      return Res(
          ((res.data!["files"] as List)
              .map((e) => ServerFile.fromJson(e))
              .toList()),
          subData: res.data!["maxPage"]);
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<bool>> deleteFile(String id) async {
    if (!appdata.isLogin) return const Res.error("Not Login");
    try {
      var res = await dio.delete("/api/file/delete/$id");
      if (res.statusCode != 200) {
        return const Res.error("Invalid Response");
      }
      return const Res(true);
    } catch (e) {
      return Res.error(e.toString());
    }
  }
}

void setDebugProxy() {
  HttpOverrides.global = _ProxyHttpOverrides();
}

class _ProxyHttpOverrides extends HttpOverrides {
  String findProxy(Uri uri) {
    return "PROXY localhost:9000";
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionTimeout = const Duration(seconds: 5);
    client.findProxy = findProxy;
    return client;
  }
}
