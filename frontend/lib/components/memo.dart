import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/components/dialog.dart';
import 'package:frontend/components/math.dart';
import 'package:frontend/components/user.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/pages/memo_edit_page.dart';
import 'package:frontend/pages/show_image_page.dart';
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
  const MemoWidget({super.key, required this.memo, this.showUser = true, this.deleteMemoCallback});

  final Memo memo;

  final bool showUser;

  final void Function()? deleteMemoCallback;

  @override
  State<MemoWidget> createState() => _MemoWidgetState();
}

class _MemoWidgetState extends State<MemoWidget> {
  bool isLiking = false;

  static const _maxLines = 16;

  bool get editable =>
      widget.memo.author == null ||
      widget.memo.author!.username == appdata.userOrNull?.username;

  void Function(int)? getOnTapTask() {
    return editable ? onTapTask : null;
  }

  void onTapTask(int taskIndex) async {
    var originContent = widget.memo.content;
    setState(() {
      updating = true;
      widget.memo.content =
          updateContentWithTaskIndex(widget.memo.content, taskIndex);
    });
    var res = await Network()
        .editMemo(widget.memo.content, widget.memo.isPublic, widget.memo.id);
    if (mounted) {
      if (res.success) {
        setState(() {
          updating = false;
        });
      } else {
        setState(() {
          updating = false;
          widget.memo.content = originContent;
        });
        context.showMessage(res.errorMessage!);
      }
    }
  }

  bool updating = false;

  @override
  Widget build(BuildContext context) {
    var content = widget.memo.content;
    bool isFolded = content.split('\n').length > _maxLines;
    content = isFolded
        ? content.split('\n').sublist(0, _maxLines).join('\n')
        : content;
    return SelectionArea(
        child: InkWell(
      onTap: () async {
        await context.to("/post/${widget.memo.id}", {
          'memo': widget.memo,
        });
        if (editable) {
          setState(() {});
        }
      },
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
          padding: const EdgeInsets.all(16),
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
                              style: ts.bold.s14),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 400),
                          child: ScrollConfiguration(
                            behavior: const ScrollBehavior()
                                .copyWith(scrollbars: false),
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: MemoContent(
                                content: content,
                                onTapTask: getOnTapTask(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  )
                ],
              ),
              if (!widget.memo.isPublic)
                Row(
                  children: [
                    Icon(
                      Icons.lock,
                      size: 18,
                      color: context.colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Private".tl,
                      style: ts.withColor(context.colorScheme.secondary),
                    ),
                  ],
                ).paddingLeft(widget.showUser ? 42 : 8).paddingBottom(8),
              Row(
                children: [
                  if (widget.memo.author != null && widget.showUser)
                    const SizedBox(width: 36),
                  if (updating)
                    SizedBox(
                      height: 34,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 8,
                          ),
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text("Updating".tl),
                        ],
                      ),
                    ),
                  if (!updating)
                    Button.normal(
                        onPressed: like,
                        isLoading: isLiking,
                        padding: const EdgeInsets.all(8),
                        child: widget.memo.isLiked
                            ? const Icon(Icons.favorite,
                                size: 18, color: Colors.red)
                            : const Icon(
                                Icons.favorite_border,
                                size: 18,
                              )),
                  if (!updating)
                    Text(
                      widget.memo.likesCount.toString(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  if (!updating)
                    const SizedBox(
                      width: 16,
                    ),
                  if (!updating)
                    Button.normal(
                      onPressed: () {
                        CommentsPage.show(widget.memo.id);
                      },
                      isLoading: isLiking,
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.chat_bubble_outline,
                        size: 18,
                      ),
                    ),
                  if (!updating)
                    Text(
                      widget.memo.repliesCount.toString(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  if (!updating)
                    const SizedBox(
                      width: 16,
                    ),
                  if (editable && !updating)
                    Button.icon(
                      key: moreActionsKey,
                      onPressed: moreActions,
                      icon: const Icon(Icons.more_horiz),
                      color: context.colorScheme.onSurface,
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
      App.rootNavigatorKey!.currentContext!.showMessage(res.errorMessage!);
    }
  }

  void reply() {
    CommentsPage.show(widget.memo.id);
  }

  var moreActionsKey = GlobalKey();

  void moreActions() async {
    var renderBox =
        moreActionsKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    var offset = renderBox.localToGlobal(Offset.zero);
    showMenu(
      elevation: 3,
      color: context.colorScheme.surface,
      context: App.rootNavigatorKey!.currentContext!,
      position:
          RelativeRect.fromLTRB(offset.dx, offset.dy, offset.dx, offset.dy),
      items: [
        PopupMenuItem(
          height: 42,
          onTap: edit,
          child: Text("Edit".tl),
        ),
        PopupMenuItem(
          height: 42,
          onTap: delete,
          child: Text("Delete".tl),
        ),
      ],
    );
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

  void delete() {
    Future.microtask(() async {
      pushDialog(
          context: App.rootNavigatorKey!.currentContext!,
          builder: (context) {
            bool isLoading = false;
            return StatefulBuilder(builder: (context, setState) {
              return DialogContent(
                title: "Delete Post".tl,
                body: Text("Are you sure you want to delete this post?".tl),
                actions: [
                  Button.text(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("Cancel".tl),
                  ),
                  Button.text(
                    color: Colors.red,
                    onPressed: () async {
                      setState(() {
                        isLoading = true;
                      });
                      var res = await Network().deleteMemo(widget.memo.id);
                      if (context.mounted) {
                        if (res.success) {
                          context.pop();
                          App.rootNavigatorKey!.currentContext!
                              .showMessage("Deleted".tl);
                          widget.deleteMemoCallback?.call();
                        } else {
                          App.rootNavigatorKey!.currentContext!
                              .showMessage(res.errorMessage!);
                          setState(() {
                            isLoading = false;
                          });
                        }
                      }
                    },
                    isLoading: isLoading,
                    child: Text("Delete".tl),
                  ),
                ],
              );
            });
          });
    });
  }
}

void _handleLink(String link) {
  if (!link.isURL) {
    var lr = link.split(':');
    if (lr.length != 2) {
      return;
    }
    var context = App.navigator!.context;
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

class HtmlImageSyntax extends m.InlineSyntax {
  HtmlImageSyntax()
      : super(r'<img\s[^>]*>', startCharacter: '<'.codeUnits.first);

  @override
  bool onMatch(m.InlineParser parser, Match match) {
    var img = match.input.substring(match.start, match.end);
    img = img.replaceFirst("<img", '');
    img = img.substring(0, img.length - 1);
    img = img.trim();
    var split = img.split(' ');
    var attributes = <String, String>{};
    for (var i = 0; i < split.length; i++) {
      var kv = split[i].split('=');
      if (kv.length == 2) {
        var key = kv[0];
        var value = kv[1].replaceAll('"', '').replaceAll("'", '');
        if (key == 'width' || key == 'height') {
          if (!value.isNum) continue;
        }
        attributes[key] = value;
      }
    }
    m.Element el = m.Element.text('img', img);
    el.attributes['src'] = attributes['src'] ?? '';
    if (attributes['width'] != null) {
      el.attributes['width'] = attributes['width']!;
    }
    if (attributes['height'] != null) {
      el.attributes['height'] = attributes['height']!;
    }
    parser.addNode(el);
    return true;
  }
}

class HtmlBlockImageSyntax extends m.BlockSyntax {
  HtmlBlockImageSyntax();

  @override
  m.Node? parse(m.BlockParser parser) {
    var img = parser.current.content;
    img = img.replaceFirst("<img", '');
    img = img.substring(0, img.length - 1);
    img = img.trim();
    parser.advance();
    var split = img.split(' ');
    var attributes = <String, String>{};
    for (var i = 0; i < split.length; i++) {
      var kv = split[i].split('=');
      if (kv.length == 2) {
        var key = kv[0];
        var value = kv[1].replaceAll('"', '').replaceAll("'", '');
        if (key == 'width' || key == 'height') {
          if (!value.isNum) continue;
        }
        attributes[key] = value;
      }
    }
    var element = m.Element.text('img', img);
    element.attributes['src'] = attributes['src'] ?? '';
    if (attributes['width'] != null) {
      element.attributes['width'] = attributes['width']!;
    }
    if (attributes['height'] != null) {
      element.attributes['height'] = attributes['height']!;
    }
    return element;
  }

  @override
  RegExp get pattern => RegExp(r'<img\s[^>]*>');
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
    final latex = MathWidget(
      content: content,
      textContent: textContent,
      style: style,
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
                    context.showMessage("Copied".tl);
                  },
                  child: const Icon(Icons.copy, size: 16),
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
    ImgConfig(builder: (link, attributes) {
      return CachedNetworkImage(
        imageUrl: link,
        filterQuality: FilterQuality.medium,
        width: attributes['width'] == null
            ? null
            : double.tryParse(attributes['width']!),
        height: attributes['height'] == null
            ? null
            : double.tryParse(attributes['height']!),
        errorWidget: (context, url, error) {
          return const Icon(Icons.broken_image,
              color: Colors.redAccent, size: 16);
        },
      ).withClickCursor().onTap(() => ShowImagePage.show(link));
    }),
  ]);
}

class TaskNode extends InputNode {
  TaskNode(super.attr, super.config);

  void Function(int index)? onTap;

  @override
  InlineSpan build() {
    bool checked = false;
    if (attr['checked'] != null) {
      checked = attr['checked']!.toLowerCase() == 'true';
    }
    Widget widget = Icon(
      checked ? Icons.check_box : Icons.check_box_outline_blank,
      color: App.rootNavigatorKey!.currentContext!.colorScheme.primary,
      size: 20,
    );
    if (onTap != null) {
      widget = InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => onTap?.call(int.tryParse(attr['index'] ?? '0') ?? 0),
        child: widget,
      );
    }
    return WidgetSpan(child: widget);
  }
}

String updateContentWithTaskIndex(String content, int index) {
  content = content.replaceAll("\r\n", "\n");
  var lines = content.split('\n');
  int taskId = -1;
  for (int i = 0; i < lines.length; i++) {
    var line = lines[i];
    if (line.length < 6) continue;
    if (line.startsWith("- [ ]") || line.startsWith("- [x]")) {
      taskId++;
      if (taskId == index) {
        if (line.startsWith("- [ ]")) {
          lines[i] = line.replaceFirst("- [ ]", "- [x]");
        } else {
          lines[i] = line.replaceFirst("- [x]", "- [ ]");
        }
        break;
      }
    }
  }
  content = lines.join('\n');
  return content;
}

MarkdownGenerator getMemoMarkdownGenerator(
    [void Function(int taskIndex)? onTapTask]) {
  const latexTag = 'latex';
  var latexGenerator = SpanNodeGeneratorWithTag(
      tag: latexTag,
      generator: (e, config, visitor) =>
          LatexNode(e.attributes, e.textContent, config));
  var taskGenerator = SpanNodeGeneratorWithTag(
      tag: 'input',
      generator: (e, config, visitor) => TaskNode(e.attributes, config));
  int taskIndex = 0;
  return MarkdownGenerator(
      generators: [latexGenerator, taskGenerator],
      inlineSyntaxList: [LatexSyntax(), HtmlImageSyntax()],
      blockSyntaxList: [HtmlBlockImageSyntax()],
      onNodeAccepted: (node, index) {
        if (node is TaskNode) {
          node.attr['index'] = taskIndex.toString();
          node.onTap = onTapTask;
          taskIndex++;
        }
      });
}

bool _isTag(String text) {
  return text.startsWith('#') &&
      text.length <= 20 &&
      text.length > 1 &&
      text[1] != '#';
}

String replaceTagWithLink(String content) {
  content = content.replaceAll("\r\n", "\n");
  var lines = content.split('\n');
  bool isCode = false;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].startsWith('```') || lines[i].startsWith('~~~')) {
      isCode = !isCode;
    }
    if (isCode) {
      continue;
    }
    var line = lines[i];
    var split = line.split(' ');
    for (var j = 0; j < split.length; j++) {
      var text = split[j];
      if (_isTag(text)) {
        split[j] = '[${split[j]}](tag:${split[j].substring(1)})';
      }
    }
    lines[i] = split.join(' ');
  }
  content = lines.join('\n');
  return content;
}

class MemoContent extends StatelessWidget {
  const MemoContent(
      {super.key,
      required this.content,
      this.selectable = false,
      this.onTapTask});

  final String content;

  final bool selectable;

  final void Function(int taskIndex)? onTapTask;

  @override
  Widget build(BuildContext context) {
    var data = replaceTagWithLink(content);
    return MarkdownBlock(
      data: data,
      selectable: selectable,
      config: getMemoMarkdownConfig(context),
      generator: getMemoMarkdownGenerator(onTapTask),
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
