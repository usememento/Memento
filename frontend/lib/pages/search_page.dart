import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/button.dart';
import 'package:frontend/components/states.dart';
import 'package:frontend/components/tab.dart';
import 'package:frontend/components/user.dart';
import 'package:frontend/foundation/app.dart';
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

  int page = 0;

  @override
  void didChangeDependencies() {
    if (initial) {
      initial = false;
      var param = context.param('keyword');
      if (param != null) {
        controller.text = param.toString();
      }
      if(controller.text.startsWith('@')) {
        page = 1;
      }
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
            delegate: SliverPersistentTopDelegate(
                height: 96 + context.padding.top,
                builder: (context) {
                  return Container(
                    height: 96,
                    margin: EdgeInsets.only(top: context.padding.top),
                    child: Column(
                      children: [
                        Row(
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
                        ).fixHeight(56),
                        IndependentTabBar(
                          initialIndex: page,
                          tabs: [
                            Tab(text: "Posts".tl,),
                            Tab(text: "Users".tl,)
                          ],
                          onTabChange: (index) {
                            setState(() {
                              page = index;
                            });
                          },
                        ).fixHeight(40)
                      ],
                    ),
                  ).withSurface();
                })),
        if (controller.text.isNotEmpty && page == 0)
          _SearchPageMemosList(
            keyword: controller.text,
            key: Key(controller.text),
          ),
        if (controller.text.isNotEmpty && page == 1)
          _SearchPageUserList(
            key: Key(controller.text),
            keyword: controller.text,
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
        if(index == data.length - 1) {
          nextPage();
        }
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

class _SearchPageUserList extends StatefulWidget {
  const _SearchPageUserList({super.key, required this.keyword});

  final String keyword;

  @override
  State<_SearchPageUserList> createState() => _SearchPageUserListState();
}

class _SearchPageUserListState extends MultiPageLoadingState<_SearchPageUserList, User> {
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
  Widget buildContent(BuildContext context, List<User> data) {
    return SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            if(index == data.length - 1) {
              nextPage();
            }
            return UserCard(user: data[index]);
          },
          childCount: data.length,
        ));
  }

  @override
  Future<Res<List<User>>> loadData(int page) {
    return Network().searchUsers(widget.keyword, page);
  }
}
