import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/components/user.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/utils/ext.dart';
import 'package:frontend/utils/translation.dart';
import 'package:markdown_widget/config/all.dart';
import 'package:markdown_widget/widget/all.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_highlight/themes/a11y-light.dart';
import 'package:flutter_highlight/themes/a11y-dark.dart';

import '../network/network.dart';
import 'button.dart';

class MemoWidget extends StatefulWidget {
  const MemoWidget({super.key, required this.memo});

  final Memo memo;

  @override
  State<MemoWidget> createState() => _MemoWidgetState();
}

class _MemoWidgetState extends State<MemoWidget> {
  bool isLiking = false;

  static const _maxLines = 16;

  @override
  Widget build(BuildContext context) {
    var content = widget.memo.content;
    bool isFolded = content.split('\n').length > _maxLines;
    content = isFolded
        ? content.split('\n').sublist(0, _maxLines).join('\n')
        : content;
    return InkWell(
      onTap: () => context.to("/memo/${widget.memo.id}"),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: context.colorScheme.outlineVariant,
              width: 0.4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.memo.author != null)
                    Avatar(
                      url: widget.memo.author!.avatar,
                      size: 36,
                    ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.memo.author != null)
                          Text(widget.memo.author!.nickname,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        MemoContent(
                          content: content,
                        ),
                        if (isFolded)
                          Text("Click to view more".tl,
                              style: TextStyle(
                                  color: context.colorScheme.outline,
                                  fontSize: 12)),
                        const SizedBox(height: 8),
                      ],
                    ),
                  )
                ],
              ),
              Row(
                children: [
                  if (widget.memo.author != null) const SizedBox(width: 36),
                  Button.normal(
                    onPressed: like,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    isLoading: isLiking,
                    height: 36,
                    width: calcButtonWidth(widget.memo.linksCount),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.memo.isLiked)
                          const Icon(Icons.favorite,
                              size: 18, color: Colors.red)
                        else
                          const Icon(
                            Icons.favorite_border,
                            size: 18,
                          ),
                        const Spacer(),
                        Text(
                          widget.memo.linksCount.toString(),
                          style: const TextStyle(fontSize: 14),
                        ).paddingBottom(2),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Button.normal(
                    onPressed: reply,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    height: 36,
                    width: calcButtonWidth(widget.memo.repliesCount),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 18,
                        ),
                        const Spacer(),
                        Text(
                          widget.memo.repliesCount.toString(),
                          style: const TextStyle(fontSize: 14),
                        ).paddingBottom(2),
                      ],
                    ),
                  ),
                  if (widget.memo.author == null ||
                      widget.memo.author!.username == appdata.user.username)
                    Button.normal(
                      onPressed: edit,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      height: 36,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 18,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            "Edit".tl,
                            style: const TextStyle(fontSize: 14),
                          ).paddingBottom(2),
                        ],
                      ),
                    ).paddingLeft(16),
                  const Spacer(),
                  Text(
                    widget.memo.date.toCompareString(),
                    style: TextStyle(
                        fontSize: 12, color: context.colorScheme.outline),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double calcButtonWidth(int number) {
    int numberLength = number.toString().length;
    return 54.0 + 14.0 * numberLength;
  }

  void like() async {
    setState(() {
      isLiking = true;
    });
    final res = await Network().favoriteOrUnfavorite(widget.memo.id);
    if (res.success) {
      setState(() {
        isLiking = false;
        widget.memo.isLiked = !widget.memo.isLiked;
        if (widget.memo.isLiked) {
          widget.memo.linksCount++;
        } else {
          widget.memo.linksCount--;
        }
      });
    } else {
      setState(() {
        isLiking = false;
      });
      App.navigatorKey!.currentContext!.showMessage(res.errorMessage!);
    }
  }

  void reply() {}

  void edit() {}
}

class MemoContent extends StatelessWidget {
  const MemoContent(
      {super.key, required this.content, this.selectable = false});

  final String content;

  final bool selectable;

  void handleLink(String link) {
    if (!link.isURL) {
      var lr = link.split(':');
      if (lr.length != 2) {
        return;
      }
      var context = App.navigatorKey!.currentContext!;
      switch (lr[0]) {
        case 'tag':
          context.to('/tag/${lr[1]}');
        case 'user':
          context.to('/user/${lr[1]}');
      }
    } else {
      launchUrlString(link);
    }
  }

  @override
  Widget build(BuildContext context) {
    var data = content;
    var lines = data.split('\n');
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      var split = line.split(' ');
      for (var j = 0; j < split.length; j++) {
        var text = split[j];
        if (isTag(text)) {
          split[j] = '[${split[j]}](tag:${split[j].substring(1)})';
        }
      }
      lines[i] = split.join(' ');
    }
    data = lines.join('\n');
    return MarkdownBlock(
      data: data,
      selectable: selectable,
      config: MarkdownConfig(configs: [
        const PConfig(textStyle: TextStyle()),
        LinkConfig(
          style: TextStyle(color: context.colorScheme.primary),
          onTap: handleLink,
        ),
        const _H1Config(),
        const _H2Config(),
        const _H3Config(),
        const H4Config(
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const H5Config(
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const H6Config(
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        PreConfig(
          theme: context.colorScheme.brightness == Brightness.dark
              ? a11yDarkTheme
              : a11yLightTheme,
          textStyle: const TextStyle(
            fontFamily: 'Consolas',
            fontSize: 14,
            fontFamilyFallback: ['Monaco', 'Courier New', 'monospace', 'Arial'],
          ),
          decoration: const BoxDecoration(),
          padding: EdgeInsets.zero,
          wrapper: (child, code, lang) => Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: context.colorScheme.brightness == Brightness.dark
                  ? const Color(0xff323232)
                  : const Color(0xffeff1f3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      lang,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Spacer(),
                    Button.normal(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.copy, size: 16),
                          const SizedBox(width: 4,),
                          Text("Copy".tl, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(),
                child,
              ],
            ),
          ),
        ),
        CodeConfig(
            style: TextStyle(
                backgroundColor: context.colorScheme.surfaceContainer)),
        BlockquoteConfig(
          sideColor: context.colorScheme.outline,
          textColor: context.colorScheme.outline,
        ),
      ]),
    );
  }

  bool isTag(String text) {
    return text.startsWith('#') &&
        text.length <= 20 &&
        text.length > 1 &&
        text[1] != '#';
  }
}

class _H1Config extends H1Config {
  const _H1Config();

  @override
  TextStyle get style =>
      const TextStyle(fontSize: 26, fontWeight: FontWeight.bold);

  @override
  HeadingDivider? get divider => null;
}

class _H2Config extends H2Config {
  const _H2Config();

  @override
  TextStyle get style =>
      const TextStyle(fontSize: 22, fontWeight: FontWeight.bold);

  @override
  HeadingDivider? get divider => null;
}

class _H3Config extends H3Config {
  const _H3Config();

  @override
  TextStyle get style =>
      const TextStyle(fontSize: 20, fontWeight: FontWeight.bold);

  @override
  HeadingDivider? get divider => null;
}
