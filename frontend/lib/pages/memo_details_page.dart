import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/button.dart';
import 'package:frontend/components/expansion_panel.dart';
import 'package:frontend/components/memo.dart';
import 'package:frontend/components/user.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/pages/comments_page.dart';
import 'package:frontend/utils/translation.dart';
import 'package:markdown_widget/config/all.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';

import '../network/network.dart';

class MemoDetailsPage extends StatefulWidget {
  const MemoDetailsPage({super.key});

  @override
  State<MemoDetailsPage> createState() => _MemoDetailsPageState();
}

class _MemoDetailsPageState extends State<MemoDetailsPage> {
  late String id;

  Memo? memo;

  bool isLoading = true;

  void load() async {
    var res = await Network().getMemoById(id);
    if (mounted) {
      if (res.success) {
        setState(() {
          memo = res.data;
          isLoading = false;
        });
      } else {
        context.showMessage(res.message);
      }
    }
  }

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
    if (isLoading || memo == null) {
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
    return Material(
      color: context.colorScheme.surface,
      child: Row(
        children: [
          if (Navigator.of(context).canPop())
            Tooltip(
              message: "Back",
              child: IconButton(
                icon: const Icon(Icons.arrow_back_sharp),
                onPressed: () {
                  context.pop();
                },
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: buildActions(),
          ),
        ],
      )
          .fixHeight(56)
          .paddingTop(
              (App.isMobile || context.width <= 600) ? context.padding.top : 0)
          .paddingHorizontal(8),
    );
  }

  void showSidebar() {
    App.rootNavigatorKey!.currentState!.push(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 200),
        opaque: false,
        fullscreenDialog: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return AnimatedBuilder(
            animation: CurvedAnimation(parent: animation, curve: Curves.ease),
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
                            color: context.colorScheme.outlineVariant,
                            width: 0.4,
                          ),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            buildSearchBar(),
                            buildOutline()
                          ],
                        ),
                      ),
                    ).withSurface(),
                  )
                ],
              );
            },
          );
        }));
  }

  String? title;

  _OutlineItem? _article;

  List<Toc>? toc;

  final controller = ItemScrollController();

  final positionsListener = ItemPositionsListener.create();

  bool get editable =>
      widget.memo.author == null ||
      widget.memo.author!.username == appdata.userOrNull?.username;

  void Function(int)? getOnTapTask() {
    return editable ? onTapTask : null;
  }

  bool updating = false;

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
          cachedMarkdownContent = null;
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

  List<Widget>? cachedMarkdownContent;

  List<Widget> generateMarkdownContent() {
    if (cachedMarkdownContent == null) {
      var content = replaceTagWithLink(widget.memo.content);
      cachedMarkdownContent =
          getMemoMarkdownGenerator(getOnTapTask()).buildWidgets(onTocList: (t) {
        toc ??= t;
        title ??= t.firstOrNull?.node.build().toPlainText();
      }, content, config: getMemoMarkdownConfig(context));
    }
    return cachedMarkdownContent!;
  }

  int currentIndex = 0;

  bool onScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      var index = positionsListener.itemPositions.value.firstOrNull?.index;
      if(index != null && index != currentIndex) {
        setState(() {
          currentIndex = index;
        });
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    var markdownContent = generateMarkdownContent();
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
                        child: NotificationListener<ScrollNotification>(
                          onNotification: onScroll,
                          child: ScrollablePositionedList.builder(
                            padding: EdgeInsets.zero,
                            itemCount: markdownContent.length,
                            itemScrollController: controller,
                            itemPositionsListener: positionsListener,
                            itemBuilder: (context, index) {
                              return markdownContent[index].paddingHorizontal(16);
                            },
                          ),
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
                    const SizedBox(height: 8),
                    buildSearchBar(),
                    buildOutline()
                  ],
                ),
              ),
            )
        ],
      );
    }).withSurface();
  }

  bool isLiking = false;

  double calcButtonWidth(int number) {
    int numberLength = number.toString().length;
    return 54.0 + 14.0 * numberLength;
  }

  Widget buildActions() {
    return Row(
      children: [
        if (!updating)
          InkWell(
            onTap: () {
              context.to('/user/${widget.memo.author!.username}');
            },
            borderRadius: BorderRadius.circular(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Avatar(url: widget.memo.author!.avatar, size: 24),
                const SizedBox(width: 8),
                Text(widget.memo.author!.nickname,
                    style: const TextStyle(fontSize: 14)),
              ],
            ).paddingHorizontal(8).paddingVertical(4),
          )
        else
          SizedBox(
            height: 40,
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
        const Spacer(),
        Button.normal(
            onPressed: like,
            isLoading: isLiking,
            padding: const EdgeInsets.all(8),
            child: widget.memo.isLiked
                ? const Icon(Icons.favorite, size: 18, color: Colors.red)
                : const Icon(
                    Icons.favorite_border,
                    size: 18,
                  )),
        Text(
          widget.memo.likesCount.toString(),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(
          width: 16,
        ),
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
        Text(
          widget.memo.repliesCount.toString(),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(
          width: 16,
        ),
        Button.normal(
          onPressed: () {},
          onPressedAt: (location) {
            var baseUrl = appdata.domain;
            var url = '$baseUrl/public/article/${widget.memo.id}';
            showPopMenu(location, [
              MenuEntry("Copy path".tl, () {
                Clipboard.setData(ClipboardData(text: url));
              }),
              MenuEntry("Share".tl, () {
                Share.share(url);
              }),
            ]);
          },
          padding: const EdgeInsets.all(8),
          child: const Icon(
            Icons.share,
            size: 18,
          ),
        ),
      ],
    );
  }

  void like() async {
    setState(() {
      isLiking = true;
    });
    var res =
        await Network().likeOrUnlike(widget.memo.id, !widget.memo.isLiked);
    if (mounted) {
      if (res.success) {
        setState(() {
          widget.memo.isLiked = !widget.memo.isLiked;
          if (widget.memo.isLiked) {
            widget.memo.likesCount++;
          } else {
            widget.memo.likesCount--;
          }
          isLiking = false;
        });
      } else {
        context.showMessage(res.message);
        setState(() {
          isLiking = false;
        });
      }
    }
  }

  Widget buildSearchBar() {
    return Container(
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
    );
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

    MyExpansionPanel buildNode(_OutlineItem node, bool isActive) {
      var children = <MyExpansionPanel>[];
      for(int i = 0; i<node.children.length; i++) {
        var current = node.children[i];
        var next = node.children.elementAtOrNull(i+1);
        var active = isActive && current.index <= currentIndex
            && (next == null || next.index > currentIndex);
        children.add(buildNode(current, active));
      }
      return MyExpansionPanel(
        headerBuilder: (context, isExpanded) {
          return ListTile(
            title: Text(
              node.title,
              style: ts.s14.withColor(isActive ? null : context.colorScheme.outline),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            minTileHeight: 32.0,
            contentPadding: padding + EdgeInsets.only(left: node.level * 12.0),
            onTap: () {
              to(node.index);
            },
            trailing: node.children.isEmpty ? null : Button.icon(
              size: 18.0,
              icon: Icon(
                node.isExpanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_left,
              ),
              onPressed: () {
                setState(() {
                  node.isExpanded = !node.isExpanded;
                });
              },
            ),
          );
        },
        body: MyExpansionPanelList(
          elevation: 0,
          materialGapSize: 0,
          expandedHeaderPadding: EdgeInsets.zero,
          children: children,
          dividerColor: Colors.transparent,
        ),
        isExpanded: node.isExpanded,
      );
    }

    return MyExpansionPanelList(
      elevation: 0,
      materialGapSize: 0,
      expandedHeaderPadding: EdgeInsets.zero,
      dividerColor: Colors.transparent,
      children: [buildNode(_article!, true)],
    ).paddingTop(4);
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
