import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/button.dart';
import 'package:frontend/components/expansion_panel.dart';
import 'package:frontend/components/memo.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/utils/translation.dart';
import 'package:markdown_widget/config/all.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../network/models.dart';

class MemoDetailsPage extends StatefulWidget {
  const MemoDetailsPage({super.key});

  @override
  State<MemoDetailsPage> createState() => _MemoDetailsPageState();
}

class _MemoDetailsPageState extends State<MemoDetailsPage> {
  late final String id;

  Memo? memo;

  bool isLoading = true;

  void load() async {}

  @override
  void didChangeDependencies() {
    Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    id = args["id"];
    memo = args['memo'];
    if (memo == null) {
      load();
    } else {
      isLoading = false;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Column(
        children: [
          Appbar(title: ''),
          Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        ],
      );
    } else {
      return _MemoDetails(memo: memo!);
    }
  }
}

class _MemoDetails extends StatefulWidget {
  const _MemoDetails({required this.memo});

  final Memo memo;

  @override
  State<_MemoDetails> createState() => _MemoDetailsState();
}

class _MemoDetailsState extends State<_MemoDetails> {
  Widget buildLeading() {
    return Appbar(
      title: title ?? 'Memo'.tl,
      primary: App.isMobile || context.width <= 600,
      color: context.colorScheme.surface.withOpacity(0.6),
      actions: [
        if (context.width <= 600)
          Tooltip(
            message: 'Outline'.tl,
            child: Button.icon(
              icon: const Icon(Icons.format_list_bulleted),
              onPressed: () {
                App.rootNavigatorKey!.currentState!.push(PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 200),
                    opaque: false,
                    fullscreenDialog: true,
                    pageBuilder: (context, animation, secondaryAnimation) {
                      return AnimatedBuilder(
                        animation: CurvedAnimation(
                            parent: animation, curve: Curves.ease),
                        builder: (context, child) {
                          var value = animation.value;
                          return Stack(
                            children: [
                              Positioned.fill(
                                  child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  color: Colors.black.withOpacity(0.4 * value),
                                ),
                              )),
                              Positioned(
                                right: -300 * (1 - value),
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  height: double.infinity,
                                  width: 300,
                                  padding: EdgeInsets.only(
                                    top: context.padding.top,
                                    bottom: context.padding.bottom,
                                    left: 8,
                                    right: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.colorScheme.surface,
                                    border: Border(
                                      left: BorderSide(
                                        color:
                                            context.colorScheme.outlineVariant,
                                        width: 0.4,
                                      ),
                                    ),
                                  ),
                                  child: SingleChildScrollView(
                                    child: buildOutline(),
                                  ),
                                ).withSurface(),
                              )
                            ],
                          );
                        },
                      );
                    }));
              },
            ),
          )
      ],
    );
  }

  String? title;

  _OutlineItem? _article;

  List<Toc>? toc;

  final controller = ItemScrollController();

  Widget buildTrailing() {
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    var markdownContent =
        getMemoMarkdownGenerator().buildWidgets(onTocList: (t) {
      toc ??= t;
      title ??= t.first.node.build().toPlainText();
    }, widget.memo.content, config: getMemoMarkdownConfig(context));
    return LayoutBuilder(builder: (context, constrains) {
      return Row(
        children: [
          Expanded(
            child: Column(
              children: [
                buildLeading(),
                Expanded(
                  child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: SelectionArea(
                        child: ScrollablePositionedList.builder(
                          padding: EdgeInsets.zero,
                          itemCount: markdownContent.length + 1,
                          itemScrollController: controller,
                          itemBuilder: (context, index) {
                            if (index == markdownContent.length) {
                              return buildTrailing();
                            }
                            return markdownContent[index].paddingHorizontal(16);
                          },
                        ),
                      )),
                )
              ],
            ),
          ),
          if (context.width > 600)
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
                    buildOutline()
                  ],
                ),
              ),
            )
        ],
      );
    }).withSurface();
  }

  Widget buildOutline() {
    void placeItem(_OutlineItem item, _OutlineItem parent) {
      for (var i = parent.children.length - 1; i >= 0; i--) {
        if (parent.children[i].level < item.level) {
          placeItem(item, parent.children[i]);
          return;
        }
      }
      parent.children.add(item);
    }

    if (_article == null) {
      _article = _OutlineItem('root', 'Outline'.tl, [], 0);
      for (var item in toc!) {
        var current = _OutlineItem(item.node.headingConfig.tag,
            item.node.build().toPlainText(), [], item.widgetIndex);
        placeItem(current, _article!);
      }
    }

    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 16);

    MyExpansionPanel buildNode(_OutlineItem node) {
      return MyExpansionPanel(
        headerBuilder: (context, isExpanded) {
          return ListTile(
            title: Text(
              node.title,
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            minTileHeight: 32.0,
            contentPadding: padding + EdgeInsets.only(left: node.level * 8.0),
            onTap: () {
              to(node.index);
            },
            trailing: node.children.isNotEmpty
                ? Button.icon(
                    size: 18.0,
                    icon: Icon(
                      node.isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                    ),
                    onPressed: () {
                      setState(() {
                        node.isExpanded = !node.isExpanded;
                      });
                    },
                  )
                : null,
          );
        },
        body: MyExpansionPanelList(
          elevation: 0,
          materialGapSize: 0,
          expandedHeaderPadding: EdgeInsets.zero,
          children: node.children.map((e) => buildNode(e)).toList(),
        ),
        isExpanded: node.isExpanded,
      );
    }

    return MyExpansionPanelList(
      elevation: 0,
      materialGapSize: 0,
      expandedHeaderPadding: EdgeInsets.zero,
      children: [buildNode(_article!)],
    );
  }

  void to(int widgetIndex) {
    controller.scrollTo(
      index: widgetIndex,
      duration: const Duration(milliseconds: 200),
      curve: Curves.ease,
    );
  }
}

class _OutlineItem {
  final String tag;

  final String title;

  final int index;

  bool isExpanded = true;

  List<_OutlineItem> children;

  int get level => const ["h1", "h2", "h3", "h4", "h5", "h6"].indexOf(tag);

  _OutlineItem(this.tag, this.title, this.children, this.index);
}
