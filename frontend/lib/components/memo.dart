import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:frontend/components/user.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/pages/memo_edit_page.dart';
import 'package:frontend/utils/ext.dart';
import 'package:frontend/utils/translation.dart';
import 'package:markdown/markdown.dart' as m;
import 'package:markdown_widget/markdown_widget.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_highlight/themes/a11y-light.dart';
import 'package:flutter_highlight/themes/a11y-dark.dart';

import '../network/network.dart';
import '../pages/comments_page.dart';
import 'button.dart';

class MemoWidget extends StatefulWidget {
  const MemoWidget({super.key, required this.memo, this.showUser = true});

  final Memo memo;

  final bool showUser;

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
    return SelectionArea(
        child: InkWell(
      onTap: () => context.to("/memo/${widget.memo.id}", {
        'memo': widget.memo,
      }),
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
                  if (widget.memo.author != null && widget.showUser)
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
                        if (widget.memo.author != null && widget.showUser)
                          Text(widget.memo.author!.nickname,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 400),
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: MemoContent(
                              content: content,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  )
                ],
              ),
              Row(
                children: [
                  if (widget.memo.author != null && widget.showUser)
                    const SizedBox(width: 36),
                  Button.normal(
                    onPressed: like,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    isLoading: isLiking,
                    height: 36,
                    width: calcButtonWidth(widget.memo.likesCount),
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
                          widget.memo.likesCount.toString(),
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
    ));
  }

  double calcButtonWidth(int number) {
    int numberLength = number.toString().length;
    return 54.0 + 14.0 * numberLength;
  }

  void like() async {
    setState(() {
      isLiking = true;
    });
    final res =
        await Network().likeOrUnlike(widget.memo.id, !widget.memo.isLiked);
    if (res.success) {
      setState(() {
        isLiking = false;
        widget.memo.isLiked = !widget.memo.isLiked;
        if (widget.memo.isLiked) {
          widget.memo.likesCount++;
        } else {
          widget.memo.likesCount--;
        }
      });
    } else {
      setState(() {
        isLiking = false;
      });
      App.navigatorKey!.currentContext!.showMessage(res.errorMessage!);
    }
  }

  void reply() {
    CommentsPage.show(widget.memo.id);
  }

  void edit() async {
    var res =
        await context.toWidget((context) => MemoEditPage(memo: widget.memo));
    if (res is Map) {
      widget.memo.content = res['content'];
      widget.memo.isPublic = res['isPublic'];
      if (mounted) {
        setState(() {});
      }
    }
  }
}

void _handleLink(String link) {
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

SpanNodeGeneratorWithTag latexGenerator = SpanNodeGeneratorWithTag(
    tag: _latexTag,
    generator: (e, config, visitor) =>
        LatexNode(e.attributes, e.textContent, config));

const _latexTag = 'latex';

class LatexSyntax extends m.InlineSyntax {
  LatexSyntax() : super(r'(\$\$[\s\S]+\$\$)|(\$.+?\$)');

  @override
  bool onMatch(m.InlineParser parser, Match match) {
    final input = match.input;
    final matchValue = input.substring(match.start, match.end);
    String content = '';
    bool isInline = true;
    const blockSyntax = '\$\$';
    const inlineSyntax = '\$';
    if (matchValue.startsWith(blockSyntax) &&
        matchValue.endsWith(blockSyntax) &&
        (matchValue != blockSyntax)) {
      content = matchValue.substring(2, matchValue.length - 2);
      isInline = false;
    } else if (matchValue.startsWith(inlineSyntax) &&
        matchValue.endsWith(inlineSyntax) &&
        matchValue != inlineSyntax) {
      content = matchValue.substring(1, matchValue.length - 1);
    }
    m.Element el = m.Element.text(_latexTag, matchValue);
    el.attributes['content'] = content;
    el.attributes['isInline'] = '$isInline';
    parser.addNode(el);
    return true;
  }
}

class LatexNode extends SpanNode {
  final Map<String, String> attributes;
  final String textContent;
  final MarkdownConfig config;

  LatexNode(this.attributes, this.textContent, this.config);

  @override
  InlineSpan build() {
    final content = attributes['content'] ?? '';
    final isInline = attributes['isInline'] == 'true';
    final style = parentStyle ?? config.p.textStyle;
    if (content.isEmpty) return TextSpan(style: style, text: textContent);
    final latex = Math.tex(
      content,
      mathStyle: MathStyle.text,
      textStyle: style,
      textScaleFactor: 1,
      onErrorFallback: (error) {
        return Text(
          textContent,
          style: style.copyWith(color: Colors.red),
        );
      },
    );
    return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: !isInline
            ? Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 16),
                child: Center(child: latex),
              )
            : latex);
  }
}

MarkdownConfig getMemoMarkdownConfig(BuildContext context) {
  return MarkdownConfig(configs: [
    const PConfig(textStyle: TextStyle()),
    LinkConfig(
      style: TextStyle(color: context.colorScheme.primary),
      onTap: _handleLink,
    ),
    const _H1Config(),
    const _H2Config(),
    const _H3Config(),
    const H4Config(style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    const H5Config(style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    const H6Config(style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.copy, size: 16),
                      const SizedBox(
                        width: 4,
                      ),
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
        style:
            TextStyle(backgroundColor: context.colorScheme.surfaceContainer)),
    BlockquoteConfig(
      sideColor: context.colorScheme.outline,
      textColor: context.colorScheme.outline,
    ),
  ]);
}

MarkdownGenerator getMemoMarkdownGenerator() {
  const latexTag = 'latex';
  SpanNodeGeneratorWithTag latexGenerator = SpanNodeGeneratorWithTag(
      tag: latexTag,
      generator: (e, config, visitor) =>
          LatexNode(e.attributes, e.textContent, config));
  return MarkdownGenerator(
    generators: [latexGenerator],
    inlineSyntaxList: [LatexSyntax()],
  );
}

class MemoContent extends StatelessWidget {
  const MemoContent(
      {super.key, required this.content, this.selectable = false});

  final String content;

  final bool selectable;

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
      config: getMemoMarkdownConfig(context),
      generator: getMemoMarkdownGenerator(),
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
