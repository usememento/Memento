import 'package:flutter/material.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/utils/translation.dart';

import '../components/appbar.dart';
import '../components/button.dart';
import '../network/network.dart';

class MemoEditPage extends StatefulWidget {
  const MemoEditPage({super.key, required this.memo});

  final Memo memo;

  @override
  State<MemoEditPage> createState() => _MemoEditPageState();
}

class _MemoEditPageState extends State<MemoEditPage> {
  late var controller = MemoEditingController(text: widget.memo.content);

  late var isPublic = widget.memo.isPublic;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Appbar(
          title: "Writing".tl,
          actions: [
            Text(
              controller.text.length.toString(),
              style: TextStyle(color: context.colorScheme.primary),
            ),
          ],
        ),
        Expanded(
          child: Container(
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Write what you think...",
                border: InputBorder.none,
                contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
              controller: controller,
              onChanged: (value) {
                setState(() {});
              },
              maxLines: null,
              expands: true,
            ).fixWidth(double.infinity),
          ),
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
                onPressed: () {}),
            Button.icon(
                icon: const Icon(Icons.info_outline),
                size: 18,
                tooltip: "Content syntax".tl,
                onPressed: () {}),
            const Spacer(),
            Button.filled(
              onPressed: post,
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
    var res = await Network().editMemo(controller.text, isPublic, widget.memo.id);
    if (mounted) {
      if(res.error) {
        context.showMessage(res.errorMessage!);
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

class MemoEditingController extends TextEditingController {
  MemoEditingController({super.text});

  bool isTag(String text) {
    return text.startsWith('#') &&
        text.length <= 20 &&
        text.length > 1 &&
        text[1] != '#';
  }

  bool isTitle(String line) {
    var splits = line.split(' ');
    if (splits.length == 1) return false;
    if (splits[1].trim().isEmpty) return false;
    var s = splits.first;
    bool isTitle = true;
    for (var char in s.characters) {
      if (char != '#') {
        isTitle = false;
        break;
      }
    }
    return isTitle;
  }

  @override
  TextSpan buildTextSpan(
      {required BuildContext context,
        TextStyle? style,
        required bool withComposing}) {
    var lines = text.split("\n");
    var spans = <TextSpan>[];
    for (int i = 0; i < lines.length; i++) {
      var line = lines[i];
      if (i != lines.length - 1) {
        line += '\n';
      }
      if (isTitle(line)) {
        spans.add(TextSpan(
          text: line,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
      } else if (!line.contains('#')) {
        spans.add(TextSpan(
          text: line,
        ));
      } else {
        var buffer = '';
        var splits = line.split(' ');
        for (var s in splits) {
          if (isTag(s)) {
            spans.add(TextSpan(
              text: buffer,
            ));
            spans.add(TextSpan(
              text: '$s ',
              style: const TextStyle(
                color: Colors.blue,
              ),
            ));
            buffer = '';
          } else {
            buffer += '$s ';
          }
        }
        if (buffer.isNotEmpty) {
          spans.add(TextSpan(
            text: buffer,
          ));
        }
      }
    }
    return TextSpan(children: spans, style: style);
  }
}

