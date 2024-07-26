import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/button.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/utils/file_type.dart';
import 'package:frontend/utils/translation.dart';
import 'package:photo_view/photo_view.dart';

class ShowImagePage extends StatelessWidget {
  const ShowImagePage({super.key, required this.url});

  final String url;

  static dynamic contextMenuListener(html.Event event) {
    event.preventDefault();
  }

  static void show(String url) {
    html.document.addEventListener("contextmenu", contextMenuListener);
    App.rootNavigatorKey!.currentState!.push(PageRouteBuilder(
        fullscreenDialog: true,
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.6),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(parent: animation, curve: Curves.ease)),
            child: ShowImagePage(
              url: url,
            ),
          );
        })).then((value) {
      html.document.removeEventListener("contextmenu", contextMenuListener);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onLongPressEnd: (details) {
          _showMenu(details.globalPosition, context);
        },
        onSecondaryTapUp: (details) {
          _showMenu(details.globalPosition, context);
        },
        onTap: () {
          context.pop();
        },
        child: Stack(
          children: [
            Positioned.fill(
                child: PhotoView(
                  backgroundDecoration: const BoxDecoration(color: Colors.transparent),
                  imageProvider: CachedNetworkImageProvider(url),
                  filterQuality: FilterQuality.medium,
                )),
            Positioned(
              left: 8,
              top: 8 + context.padding.top,
              child: Button.icon(
                  icon: const Icon(Icons.close),
                  color: Colors.white,
                  onPressed: () {
                    context.pop();
                  }),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(Offset position, BuildContext context) {
    showMenu(
      context: App.rootNavigatorKey!.currentContext!,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      color: context.colorScheme.surface,
      items: [
        PopupMenuItem(
          onTap: saveImage,
          height: 42,
          child: Text("Save Image".tl)
        ),
      ]
    );
  }

  void saveImage() async {
    Uint8List? data;
    if (App.isWeb) {
      var res = await Dio().get(url, options: Options(responseType: ResponseType.bytes));
      data = res.data;
    } else {
      var file = await DefaultCacheManager().getSingleFile(url);
      data = await file.readAsBytes();
    }
    final ext = detectFileType(data!).name;
    if (!App.isWeb) {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Please select an output file:',
        fileName: 'image.$ext',
        bytes: data,
      );
      if(path != null && App.isDesktop) {
        File(path).writeAsBytes(data);
      }
    } else {
      final base64data = base64Encode(data);
      final a = html.AnchorElement(href: 'data:image/jpeg;base64,$base64data');
      a.download = 'image.$ext';
      a.click();
      a.remove();
    }
  }
}
