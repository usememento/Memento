import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/button.dart';
import 'package:frontend/components/states.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/network/models.dart';
import 'package:frontend/network/res.dart';
import 'package:frontend/utils/translation.dart';

import '../components/memo.dart';
import '../network/network.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  var controller = TextEditingController();

  bool initial = true;

  @override
  void didChangeDependencies() {
    if (initial) {
      initial = false;
      var param = context.param('keyword');
      if (param != null) {
        controller.text = param.toString();
      }
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
            delegate: SliverPersistentTopDelegate(
                height: 56 + context.padding.top,
                builder: (context) {
                  return Container(
                    height: 56,
                    margin: EdgeInsets.only(top: context.padding.top),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: context.colorScheme.outlineVariant,
                                width: 0.6))),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 8,
                        ),
                        Tooltip(
                          message: "Back".tl,
                          child: Button.icon(
                            icon: const Icon(Icons.arrow_back),
                            color: context.colorScheme.onSurface,
                            onPressed: () {
                              context.pop();
                            },
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: "Search".tl,
                              border: InputBorder.none,
                            ),
                            onSubmitted: (value) {
                              search();
                            },
                          ),
                        ),
                        Tooltip(
                          message: "Search".tl,
                          child: Button.icon(
                              icon: const Icon(Icons.search),
                              color: context.colorScheme.onSurface,
                              onPressed: search),
                        )
                      ],
                    ),
                  );
                })),
        if (controller.text.isNotEmpty)
          _SearchPageMemosList(
            keyword: controller.text,
            key: Key(controller.text),
          )
      ],
    );
  }

  void search() {
    setState(() {});
  }
}

class _SearchPageMemosList extends StatefulWidget {
  const _SearchPageMemosList({super.key, required this.keyword});

  final String keyword;
  @override
  State<_SearchPageMemosList> createState() => _SearchPageMemosListState();
}

class _SearchPageMemosListState
    extends MultiPageLoadingState<_SearchPageMemosList, Memo> {
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
    return Network().search(widget.keyword, page);
  }
}
