import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/states.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/network/network.dart';

import '../components/memo.dart';

class TaggedMemosListPage extends StatefulWidget {
  const TaggedMemosListPage({super.key});

  @override
  State<TaggedMemosListPage> createState() => _TaggedMemosListPageState();
}

class _TaggedMemosListPageState extends State<TaggedMemosListPage> {
  late String tag;

  @override
  void didChangeDependencies() {
    tag = context.param("tag");
    if (tag.startsWith("#")) {
      tag = tag.substring(1);
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constrains) {
      return Row(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppbar(title: Text("#$tag")),
                TaggedMemosList(tag: tag),
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
                  ],
                ),
              ),
            )
        ],
      );
    });
  }
}

class TaggedMemosList extends StatefulWidget {
  const TaggedMemosList({super.key, required this.tag});

  final String tag;

  @override
  State<TaggedMemosList> createState() => _TaggedMemosListState();
}

class _TaggedMemosListState
    extends MultiPageLoadingState<TaggedMemosList, Memo> {
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
        );
      },
      childCount: data.length,
    ));
  }

  @override
  Future<Res<List<Memo>>> loadData(int page) {
    return Network().getMemosListByTag(page, widget.tag);
  }
}
