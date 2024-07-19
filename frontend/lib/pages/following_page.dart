import 'package:flutter/material.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/utils/translation.dart';

import '../components/memo.dart';
import '../components/states.dart';
import '../network/network.dart';

class FollowingPage extends StatefulWidget {
  const FollowingPage({super.key});

  @override
  State<FollowingPage> createState() => _FollowingPageState();
}

class _FollowingPageState extends State<FollowingPage> {
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
                const _ExplorePageMemosList(),
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
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: context.colorScheme.outlineVariant,
                                width: 0.6
                            )
                        )
                    ),
                  ),
                ],
              ),
            )
        ],
      );
    });
  }
}

class _ExplorePageMemosList extends StatefulWidget {
  const _ExplorePageMemosList();

  @override
  State<_ExplorePageMemosList> createState() => _ExplorePageMemosListState();
}

class _ExplorePageMemosListState
    extends MultiPageLoadingState<_ExplorePageMemosList, Memo> {
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
            if(index == data.length - 1) {
              nextPage();
            }
            return MemoWidget(memo: data[index],);
          },
          childCount: data.length,
        ));
  }

  @override
  Future<Res<List<Memo>>> loadData(int page) {
    return Network().getFollowingMemos(page);
  }
}