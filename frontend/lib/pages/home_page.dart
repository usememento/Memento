import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/button.dart';
import 'package:frontend/components/memo.dart';
import 'package:frontend/components/states.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/network/network.dart';
import 'package:frontend/utils/translation.dart';

import '../components/heat_map.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constrains) {
      return Row(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                    padding: EdgeInsets.only(top: context.padding.top)),
                const WritingArea(),
                const _HomePageMemosList(),
              ],
            ),
          ),
          if (context.width >= 600)
            Container(
              width: (constrains.maxWidth - 324).clamp(0, 286),
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16) +
                  EdgeInsets.only(
                    top: context.padding.top,
                    bottom: context.padding.bottom,
                  ),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: context.colorScheme.outlineVariant,
                    width: 0.4,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 8,
                    ),
                    Container(
                      height: 42,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: "Search",
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (s) {
                          context.to("/search", {
                            "keyword": s,
                          });
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    HeatMap(data: getTestData())
                  ],
                ),
              ),
            )
        ],
      );
    });
  }
}

class WritingArea extends StatefulWidget {
  const WritingArea({super.key});

  @override
  State<WritingArea> createState() => _WritingAreaState();
}

class _WritingAreaState extends State<WritingArea> {
  String get content => controller.text;

  var controller = MemoEditingController();

  bool isPublic = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.outlineVariant,
            width: 0.4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: "Write what you think...",
              border: InputBorder.none,
            ),
            controller: controller,
            maxLines: null,
          ).fixWidth(double.infinity),
          Container(
            height: 0.4,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 12),
            color: context.colorScheme.outlineVariant,
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
                  icon: const Icon(Icons.fullscreen),
                  size: 18,
                  tooltip: "Full screen".tl,
                  onPressed: fullScreen),
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
        ],
      ),
    ).toSliver();
  }

  void post() {
    if (content.isEmpty) {
      return;
    }
    // Post content to the server
  }

  void fullScreen() async {
    await App.rootNavigatorKey?.currentState?.push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return WritingPage(
            content: content,
            isPublic: isPublic,
            updateContent: (value, isPublic) {
              controller.text = value;
              this.isPublic = isPublic;
            });
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1.0)
              .animate(CurvedAnimation(parent: animation, curve: Curves.ease)),
          child: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0).animate(CurvedAnimation(
                parent: secondaryAnimation, curve: Curves.ease)),
            child: child,
          ),
        );
      },
    ));
    setState(() {});
  }
}

class WritingPage extends StatefulWidget {
  const WritingPage(
      {super.key,
      required this.content,
      required this.updateContent,
      this.isPublic = false});

  final String content;

  final void Function(String, bool) updateContent;

  final bool isPublic;

  @override
  State<WritingPage> createState() => _WritingPageState();
}

class _WritingPageState extends State<WritingPage> {
  late var controller = MemoEditingController(text: widget.content);

  late var isPublic = widget.isPublic;

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
                widget.updateContent(value, isPublic);
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
                  widget.updateContent(controller.text, isPublic);
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

  void post() {}
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

class _HomePageMemosList extends StatefulWidget {
  const _HomePageMemosList();

  @override
  State<_HomePageMemosList> createState() => _HomePageMemosListState();
}

class _HomePageMemosListState
    extends MultiPageLoadingState<_HomePageMemosList, Memo> {
  @override
  Widget buildLoading(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(
        child: const CircularProgressIndicator(
          strokeWidth: 2,
        ).fixWidth(18).fixHeight(18),
      ).fixHeight(64),
    );
  }

  @override
  Widget buildError(BuildContext context, String error) {
    return SliverToBoxAdapter(
      child: super.buildError(context, error),
    );
  }

  @override
  Widget buildContent(BuildContext context, List<Memo> data) {
    return SliverList(
        delegate: SliverChildBuilderDelegate(
      (context, index) {
        return MemoWidget(memo: data[index]);
      },
      childCount: data.length,
    ));
  }

  @override
  Future<Res<List<Memo>>> loadData(int page) {
    return Network().getHomePage(page);
  }
}
