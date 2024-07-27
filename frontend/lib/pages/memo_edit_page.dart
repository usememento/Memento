import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/utils/ext.dart';
import 'package:frontend/utils/translation.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
  late var controller = MemoEditingController(text: widget.memo.content);

  late var isPublic = widget.memo.isPublic;

  bool isLoading = false;

  late FocusNode focusNode;

  @override
  void initState() {
    focusNode = FocusNode()
      ..onKeyEvent = (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.tab) {
          var cursorPos = controller.selection.base.offset;
          if (cursorPos != -1) {
            String textAfterCursor = controller.text.substring(cursorPos);
            String textBeforeCursor = controller.text.substring(0, cursorPos);
            controller.value = TextEditingValue(
              text: "$textBeforeCursor    $textAfterCursor",
              selection: TextSelection.collapsed(offset: cursorPos + 4),
            );
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      };
    super.initState();
  }

  @override
  dispose() {
    focusNode.dispose();
    super.dispose();
  }

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
          child: Container(
            child: TextField(
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: "Write down your thoughts".tl,
                border: InputBorder.none,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
    if(s.isEmpty) return false;
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
    if(text.contains('\t')) {
      Future.microtask(() {
        text = text.replaceAll('\t', '    ');
      });
    }
    var lineBreak = text.contains('\r\n') ? '\r\n' : '\n';
    var lines = text.split(lineBreak);
    var spans = <TextSpan>[];
    bool isCode = false;
    for (int i = 0; i < lines.length; i++) {
      var line = lines[i];
      bool isEndLine = i == lines.length-1;
      if(line.startsWith('```') || line.startsWith('~~~')){
        isCode = !isCode;
      }
      if (!isEndLine) {
        line += lineBreak;
      }
      if(isCode || line.startsWith('```') || line.startsWith('~~~')){
        spans.add(TextSpan(
          text: line,
          style: const TextStyle(
            fontFamily: 'consolas',
            fontFamilyFallback: ['monospace', 'sans-serif', 'serif'],
          ),
        ));
      }
      else if (isTitle(line)) {
        spans.add(TextSpan(
          text: line,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
      } else if (!line.contains('#')) {
        spans.add(TextSpan(
          text: line,
        ));
      } else {
        line = line.replaceLast(lineBreak, '');
        var buffer = StringBuffer();
        bool tag = false;
        for(int i = 0; i < line.length; i++) {
          var char = line[i];
          if(tag && char == ' ') {
            buffer.write(char);
            if(buffer.length > 2) {
              spans.add(TextSpan(
                text: buffer.toString(),
                style: const TextStyle(
                  color: Colors.blue,
                ),
              ));
            } else {
              spans.add(TextSpan(
                text: buffer.toString(),
              ));
            }
            tag = false;
            buffer.clear();
            continue;
          } else if (!tag && char == '#') {
            if(i == 0 || line[i-1] == ' ') {
              spans.add(TextSpan(
                text: buffer.toString(),
              ));
              buffer.clear();
              tag = true;
            }
            buffer.write(char);
          } else {
            buffer.write(char);
          }
        }
        if(tag && buffer.length > 2) {
          spans.add(TextSpan(
            text: buffer.toString(),
            style: const TextStyle(
              color: Colors.blue,
            ),
          ));
        } else if(buffer.isNotEmpty) {
          spans.add(TextSpan(
            text: buffer.toString(),
          ));
        }
        if(!isEndLine) {
          spans.add(TextSpan(
            text: lineBreak,
          ));
        }
      }
    }
    return TextSpan(children: spans, style: style);
  }
}

