import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/button.dart';
import 'package:frontend/components/states.dart';
import 'package:frontend/components/user.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/network/network.dart';
import 'package:frontend/utils/translation.dart';

import '../components/memo.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends LoadingState<UserInfoPage, User> {
  @override
  Widget? buildFrame(BuildContext context, Widget child) {
    return child.withSurface();
  }

  var isFollowing = false;

  bool showTitle = false;

  int page = 0;

  @override
  Widget buildContent(BuildContext context, User data) {
    return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          var showTitle = notification.metrics.pixels -
                  notification.metrics.minScrollExtent >
              64;
          if (showTitle != this.showTitle) {
            setState(() {
              this.showTitle = showTitle;
            });
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            SliverAppbar(title: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: showTitle ? 1 : 0,
              child: Text(data.nickname)
            )),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Avatar(
                        url: data.avatar,
                        size: 64,
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.nickname,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            Text("@${data.username}")
                          ],
                        ),
                      ),
                      if (data.username != appdata.user.username)
                        Button.outlined(
                            width: data.isFollowed ? 84 : 72,
                            height: 28,
                            padding: EdgeInsets.zero,
                            isLoading: isFollowing,
                            onPressed: follow,
                            color: data.isFollowed ? Colors.red : null,
                            child: data.isFollowed
                                ? Text(
                                    "Unfollow".tl,
                                    style: ts.s14,
                                  )
                                : Text(
                                    "Follow".tl,
                                    style: ts.s14,
                                  ))
                    ],
                  ),
                  Text(data.bio),
                  Row(
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            context.to('/user/${data.username}/following');
                          },
                          child: Row(
                            children: [
                              Text(
                                data.totalFollows.toString(),
                                style: ts.bold,
                              ),
                              const SizedBox(
                                width: 4,
                              ),
                              Text("Following".tl)
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            context.to('/user/${data.username}/followers');
                          },
                          child: Row(
                            children: [
                              Text(
                                data.totalFollower.toString(),
                                style: ts.bold,
                              ),
                              const SizedBox(
                                width: 4,
                              ),
                              Text("Followers".tl),
                            ],
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ).paddingHorizontal(16),
            ).sliverPadding(const EdgeInsets.only(bottom: 8)),
            SliverPersistentHeader(
              pinned: true,
              delegate: SliverPersistentTopDelegate(
                  height: 42,
                  builder: (context) {
                    return _TabBar(
                      tabs: [
                        Tab(
                          text: "Memos".tl,
                          height: 42,
                        ),
                        Tab(text: "Replies".tl, height: 42),
                        Tab(text: "Likes".tl, height: 42),
                      ],
                      onTabChange: onPageChanged,
                    );
                  }),
            ),
            buildPage()
          ],
        ));
  }

  Widget buildPage() {
    if(page == 0) {
      return _UserMemosList(username: data!.username);
    }
    return const SliverToBoxAdapter();
  }

  void onPageChanged(int i) {
    setState(() {
      page = i;
    });
  }

  void follow() async {
    setState(() {
      isFollowing = true;
    });
    var res = await Network()
        .followOrUnfollow(context.param('username'), !data!.isFollowed);
    if (mounted) {
      if (res.success) {
        setState(() {
          isFollowing = false;
          data!.isFollowed = !data!.isFollowed;
          data!.totalFollower += data!.isFollowed ? 1 : -1;
        });
      } else {
        setState(() {
          isFollowing = false;
        });
        context.showMessage(res.message);
      }
    }
  }

  @override
  Future<Res<User>> loadData() {
    return Network().getUserDetails(context.param('username'));
  }
}

class UserListPage extends StatefulWidget {
  const UserListPage({super.key, required this.title, required this.loader});

  final String title;

  final Future<Res<List<User>>> Function(String userName, int page) loader;

  UserListPage.following({super.key})
      : title = "Following",
        loader = Network().getFollowing;

  UserListPage.followers({super.key})
      : title = "Followers",
        loader = Network().getFollowers;

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends MultiPageLoadingState<UserListPage, User> {
  @override
  Widget? buildFrame(BuildContext context, Widget child) {
    return Column(
      children: [Appbar(title: widget.title), Expanded(child: child)],
    );
  }

  @override
  Widget buildContent(BuildContext context, List<User> data) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        return UserCard(user: data[index]);
      },
      itemCount: data.length,
    );
  }

  @override
  Future<Res<List<User>>> loadData(int page) {
    return widget.loader(context.param('username'), page);
  }
}

class _TabBar extends StatefulWidget {
  const _TabBar({required this.tabs, required this.onTabChange});

  final void Function(int i) onTabChange;

  final List<Widget> tabs;

  @override
  State<_TabBar> createState() => _TabBarState();
}

class _TabBarState extends State<_TabBar> with SingleTickerProviderStateMixin {
  late TabController controller;

  @override
  void initState() {
    controller = TabController(length: widget.tabs.length, vsync: this);
    controller.addListener(() {
      widget.onTabChange(controller.index);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TabBar(
      tabs: widget.tabs,
      controller: controller,
      isScrollable: true,
      splashBorderRadius: BorderRadius.circular(8),
      tabAlignment: TabAlignment.start,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      labelPadding: const EdgeInsets.symmetric(horizontal: 24),
    ).withSurface();
  }
}

class _UserMemosList extends StatefulWidget {
  const _UserMemosList({required this.username});

  final String username;

  @override
  State<_UserMemosList> createState() => _UserMemosListState();
}

class _UserMemosListState extends MultiPageLoadingState<_UserMemosList, Memo> {
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
            return MemoWidget(memo: data[index], showUser: false);
          },
          childCount: data.length,
        ));
  }

  @override
  Future<Res<List<Memo>>> loadData(int page) {
    return Network().getMemosList(page, widget.username);
  }
}
