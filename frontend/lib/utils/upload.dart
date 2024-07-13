import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/button.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/utils/translation.dart';

import '../network/network.dart';

Future<ServerFile?> uploadFile(
    [TextEditingController? controller, XTypeGroup? xTypeGroup]) async {
  var typeGroup = xTypeGroup ??
      const XTypeGroup(
        label: 'images',
        extensions: <String>['jpg', 'png', 'jpeg', 'gif', 'webp'],
      );
  final XFile? file =
      await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
  ServerFile? serverFile;
  if (file != null) {
    var data = await file.readAsBytes();
    var cancelToken = CancelToken();
    await App.rootNavigatorKey!.currentState!.push(PageRouteBuilder(
      opaque: false,
      fullscreenDialog: true,
      barrierColor: Colors.black.withOpacity(0.2),
      barrierDismissible: false,
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: Tween(begin: 0.6, end: 1.0)
              .animate(CurvedAnimation(parent: animation, curve: Curves.ease)),
          child: Center(
            child: Material(
              color: context.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 97,
                width: 300,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Uploading".tl,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                    StreamBuilder(
                        stream:
                            Network().uploadFile(data, file.name, cancelToken),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            Future.microtask(() {
                              context.pop();
                              context.showMessage(snapshot.error.toString());
                            });
                            return const SizedBox();
                          }
                          if (snapshot.data is double) {
                            return LinearProgressIndicator(
                                value: snapshot.data as double);
                          }
                          if (snapshot.data is String) {
                            Future.microtask(() {
                              if (context.mounted) {
                                context.pop();
                              }
                              var baseUrl = App.isWeb
                                  ? Uri.base
                                  : appdata.settings["domain"];
                              controller?.text +=
                                  "![image]($baseUrl/api/file/download/${snapshot.data})";
                              serverFile = ServerFile(
                                  id: int.parse(snapshot.data as String),
                                  name: file.name,
                                  time: DateTime.now());
                            });
                            return const LinearProgressIndicator(value: 1);
                          }
                          return const LinearProgressIndicator();
                        }),
                    const SizedBox(
                      height: 16,
                    ),
                    Row(
                      children: [
                        const Spacer(),
                        Button.filled(
                            child: Text("Cancel".tl),
                            onPressed: () {
                              context.pop();
                              cancelToken.cancel();
                            }),
                      ],
                    )
                  ],
                ),
              ).paddingHorizontal(16).paddingVertical(8),
            ),
          ),
        );
      },
    ));
  }

  return serverFile;
}
