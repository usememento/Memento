import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/utils/translation.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:web_native_text/web_native_editable.dart';

import '../components/appbar.dart';
import '../components/button.dart';
import '../network/network.dart';
import '../utils/upload.dart';

class MemoEditPage extends StatefulWidget {
  const MemoEditPage({super.key, required this.memo});

  final Memo memo;

  @override
  State<MemoEditPage> createState() => _MemoEditPageState();
}

class _MemoEditPageState extends State<MemoEditPage> {
  late var controller = WNEditingController(text: widget.memo.content);

  late var isPublic = widget.memo.isPublic;

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Appbar(
          title: "Edit".tl,
          actions: [
            Text(
              controller.text.length.toString(),
              style: TextStyle(color: context.colorScheme.primary),
            ),
          ],
        ),
        Expanded(
          child: WNEditableText(
            hintText: "Write down your thoughts".tl,
            controller: controller,
            style: ts.s16,
            onChanged: (value) {
              setState(() {});
            },
            singleLine: false,
          ).fixWidth(double.infinity).paddingHorizontal(12),
        ),
        Row(
          children: [
            Tooltip(
              message: "Click to change visibility".tl,
              child: InkWell(
                onTap: () {
                  setState(() {
                    isPublic = !isPublic;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    if (isPublic)
                      Icon(
                        Icons.public,
                        size: 18,
                        color: context.colorScheme.primary,
                      ),
                    if (!isPublic)
                      Icon(
                        Icons.lock,
                        size: 18,
                        color: context.colorScheme.primary,
                      ),
                    const Spacer(),
                    Text(
                      isPublic ? "Public".tl : "Private".tl,
                      style: TextStyle(color: context.colorScheme.primary),
                    ),
                    const Spacer(),
                  ],
                ).fixWidth(72).paddingHorizontal(8).paddingVertical(4),
              ),
            ),
            Button.icon(
                icon: const Icon(Icons.image_outlined),
                size: 18,
                tooltip: "Upload image".tl,
                onPressed: () => uploadFile(controller, FileType.image)),
            Button.icon(
                icon: const Icon(Icons.info_outline),
                size: 18,
                tooltip: "Content syntax".tl,
                onPressed: () {
                  launchUrlString("https://github.com/usememento/Memento/blob/master/doc/ContentSyntax.md");
                }),
            const Spacer(),
            Button.filled(
              onPressed: post,
              isLoading: isLoading,
              child: Text("Post".tl),
            )
          ],
        )
            .paddingHorizontal(12)
            .paddingVertical(8)
            .paddingBottom(context.viewInsets.bottom)
      ],
    ).withSurface();
  }

  void post() async{
    if (controller.text.isEmpty) {
      return;
    }
    setState(() {
      isLoading = true;
    });
    var res = await Network().editMemo(controller.text, isPublic, widget.memo.id);
    if (mounted) {
      if(res.error) {
        context.showMessage(res.errorMessage!);
        setState(() {
          isLoading = false;
        });
      } else {
        context.showMessage("Post success".tl);
        context.pop({
          'content': controller.text,
          'isPublic': isPublic,
        });
      }
    }
  }
}
