import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/button.dart';
import 'package:frontend/components/memo.dart';
import 'package:frontend/components/states.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/network/network.dart';
import 'package:frontend/utils/translation.dart';
import 'package:frontend/utils/upload.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../components/heat_map.dart';
import 'memo_edit_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _memosListKey = 0;

  @override
  Widget build(BuildContext context) {
    if (!appdata.isLogin) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Login Required".tl,
              style: ts.bold.s16,
            ),
            const SizedBox(
              height: 12,
            ),
            Button.filled(
                child: Text("Login".tl),
                onPressed: () {
                  App.rootNavigatorKey!.currentContext!.to('/login');
                })
          ],
        ),
      );
    }
    return LayoutBuilder(builder: (context, constrains) {
      return Row(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                    padding: EdgeInsets.only(top: context.padding.top)),
                WritingArea(
                  onPost: () {
                    setState(() {
                      _memosListKey++;
                    });
                  },
                ),
                _HomePageMemosList(
                  key: ValueKey(_memosListKey),
                ),
              ],
            ),
          ),
          if (context.width >= 600)
            Container(
              width: (constrains.maxWidth - 332).clamp(0, 286),
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
                      decoration: InputDecoration(
                        hintText: "Search".tl,
                        prefixIcon: const Icon(Icons.search),
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
                  const HeatMapWithLoadingState(),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: context.colorScheme.outlineVariant,
                                width: 0.6))),
                  ),
                  Expanded(
                    child: _TagsList(key: ValueKey(_memosListKey)),
                  )
                ],
              ),
            )
        ],
      );
    });
  }
}

class WritingArea extends StatefulWidget {
  const WritingArea({super.key, required this.onPost});

  final VoidCallback onPost;

  @override
  State<WritingArea> createState() => _WritingAreaState();
}

class _WritingAreaState extends State<WritingArea> {
  String get content => controller.text;

  var controller = MemoEditingController();

  bool isPublic = true;

  bool isLoading = false;

  late FocusNode focusNode;

  @override
  void initState() {
    focusNode = FocusNode()
      ..onKeyEvent = (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.tab) {
          if(event is KeyUpEvent) {
            return KeyEventResult.ignored;
          }
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
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: "Write down your thoughts".tl,
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
                  onPressed: () => uploadFile(controller, FileType.image)),
              Button.icon(
                  icon: const Icon(Icons.fullscreen),
                  size: 18,
                  tooltip: "Full screen".tl,
                  onPressed: fullScreen),
              Button.icon(
                  icon: const Icon(Icons.info_outline),
                  size: 18,
                  tooltip: "Content syntax".tl,
                  onPressed: () {
                    launchUrlString(
                        "https://github.com/usememento/Memento/blob/master/doc/ContentSyntax.md");
                  }),
              const Spacer(),
              Button.filled(
                onPressed: post,
                isLoading: isLoading,
                child: Text("Post".tl),
              )
            ],
          )
        ],
      ),
    ).toSliver();
  }

  void post() async {
    if (content.isEmpty) {
      return;
    }
    setState(() {
      isLoading = true;
    });
    var res = await Network().postMemo(content, isPublic);
    if (mounted) {
      if (res.error) {
        context.showMessage(res.errorMessage!);
      } else {
        controller.clear();
        context.showMessage("Post success".tl);
        widget.onPost();
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  void onPost() {
    controller.clear();
    widget.onPost();
  }

  void fullScreen() async {
    await App.rootNavigatorKey?.currentState?.push(AppPageRoute(
      isRootRoute: true,
      builder: (context) {
        return WritingPage(
            content: content,
            isPublic: isPublic,
            onPost: onPost,
            updateContent: (value, isPublic) {
              controller.text = value;
              this.isPublic = isPublic;
            });
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
      required this.onPost,
      this.isPublic = false});

  final String content;

  final void Function(String, bool) updateContent;

  final void Function() onPost;

  final bool isPublic;

  @override
  State<WritingPage> createState() => _WritingPageState();
}

class _WritingPageState extends State<WritingPage> {
  late var controller = MemoEditingController(text: widget.content);

  late var isPublic = widget.isPublic;

  bool isLoading = false;

  late FocusNode focusNode;

  @override
  void initState() {
    focusNode = FocusNode()
      ..onKeyEvent = (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.tab) {
          if (event is KeyDownEvent) {
            return KeyEventResult.ignored;
          }
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
          title: "Write".tl,
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
                onPressed: () => uploadFile(controller, FileType.image)),
            Button.icon(
                icon: const Icon(Icons.info_outline),
                size: 18,
                tooltip: "Content syntax".tl,
                onPressed: () {
                  launchUrlString(
                      "https://github.com/usememento/Memento/blob/master/doc/ContentSyntax.md");
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

  void post() async {
    if (controller.text.isEmpty) {
      return;
    }
    setState(() {
      isLoading = true;
    });
    var res = await Network().postMemo(controller.text, isPublic);
    if (mounted) {
      if (res.error) {
        context.showMessage(res.errorMessage!);
        setState(() {
          isLoading = false;
        });
      } else {
        controller.clear();
        context.showMessage("Post success".tl);
        widget.onPost();
        context.pop();
      }
    }
  }
}

class _HomePageMemosList extends StatefulWidget {
  const _HomePageMemosList({super.key});

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
        if (index == data.length - 1) {
          nextPage();
        }
        return MemoWidget(
          memo: data[index],
          showUser: false,
          deleteMemoCallback: () {
            setState(() {
              data.removeAt(index);
            });
          },
        );
      },
      childCount: data.length,
    ));
  }

  @override
  Future<Res<List<Memo>>> loadData(int page) {
    return Network().getMemosList(page);
  }
}

class _TagsList extends StatefulWidget {
  const _TagsList({super.key});

  @override
  State<_TagsList> createState() => _TagsListState();
}

class _TagsListState extends LoadingState<_TagsList, List<String>> {
  @override
  Widget buildContent(BuildContext context, List<String> data) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: data.length,
      itemBuilder: (context, index) {
        var tag = data[index];
        return ListTile(
          minTileHeight: 32,
          title: Text(
            tag,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ts.withColor(context.colorScheme.primary),
          ),
          onTap: () {
            context.to("/tag/$tag");
          },
        );
      },
    );
  }

  @override
  Future<Res<List<String>>> loadData() {
    return Network().getTags("user");
  }
}
