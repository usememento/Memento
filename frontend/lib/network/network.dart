import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../foundation/appdata.dart';
import 'res.dart';
import 'models.dart';

export 'models.dart';
export 'res.dart';

class AppInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    setDebugProxy();
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
        } else if (data is Map) {
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
      var res = await Network().refresh();
      if (res.success) {
        appdata.user = res.data;
        response.requestOptions.headers["Authorization"] =
            "Bearer ${appdata.user.token}";
        Network().dio.fetch(response.requestOptions).then((value) {
          handler.resolve(value);
        });
      } else {
        handler.reject(DioException(
            requestOptions: response.requestOptions, response: response));
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
      var res = await dio.post<Map<String, dynamic>>("/api/user/refresh",
          data: {
            "refresh_token": appdata.user.refreshToken,
          },
          queryParameters: {
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
      var res = await dio.get<List>("/api/post/userPosts", queryParameters: {
        "page": page,
        "username": username ?? appdata.user.username
      });
      return Res((res.data as List).map((e) => Memo.fromJson(e)).toList());
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<List<Memo>>> getAllMemosList(int page) async {
    try {
      page--;
      var res = await dio.get<List>("/api/post/all", queryParameters: {
        "page": page,
      });
      return Res((res.data as List).map((e) => Memo.fromJson(e)).toList());
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<List<Memo>>> getMemosListByTag(int page, String tag) async {
    try {
      page--;
      var res = await dio.get<List>("/api/post/taggedPosts", queryParameters: {
        "page": page,
        "tag": "#$tag"
      });
      return Res((res.data as List).map((e) => Memo.fromJson(e)).toList());
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<bool>> likeOrUnlike(int memoId, bool isLike) async {
    try {
      var res = await dio.post(isLike ? "/api/post/like" : "/api/post/unlike",
          data: {"postId": memoId});
      if(res.statusCode == 200) {
        return const Res(true);
      } else {
        throw "Invalid Status Code ${res.statusCode}";
      }
    } catch (e) {
      return Res.error(e.toString());
    }
  }

  Future<Res<bool>> postMemo(String content, bool isPublic) async {
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
    try {
      var res = await dio.get<Map<String, dynamic>>("/api/user/heatmap",
          queryParameters: {"username": username ?? appdata.user.username});
      return Res(HeatMapData(
          Map.from(res.data!['map']), res.data!['memos'], res.data!['likes']));
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
