import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/button.dart';
import 'package:frontend/components/states.dart';
import 'package:frontend/components/user.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/network/network.dart';
import 'package:frontend/utils/ext.dart';
import 'package:frontend/utils/translation.dart';

import '../components/heat_map.dart';
import '../components/memo.dart';
import '../components/tab.dart';

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
          if (notification.metrics.axis != Axis.vertical) return false;
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
            SliverAppbar(
                title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: showTitle ? 1 : 0,
                    child: Text(data.nickname))),
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
                      if (appdata.isLogin &&
                          data.username != appdata.user.username)
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
                  Text(data.bio).paddingVertical(8),
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
                    return IndependentTabBar(
                      tabs: [
                        Tab(
                          text: "Posts".tl,
                          height: 42,
                        ),
                        Tab(text: "Replies".tl, height: 42),
                        Tab(text: "Likes".tl, height: 42),
                        Tab(text: "Statistics".tl, height: 42),
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
    return switch (page) {
      0 => _UserMemosList(username: data!.username),
      1 => _UserCommentsList(username: data!.username),
      2 => _UserLikedMemosList(username: data!.username),
      3 => _UserStats(user: data!),
      _ => const Placeholder(),
    };
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
      children: [Appbar(title: widget.title.tl), Expanded(child: child)],
    ).withSurface();
  }

  @override
  Widget buildContent(BuildContext context, List<User> data) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        if (index == data.length - 1) {
          nextPage();
        }
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
        if (index == data.length - 1) {
          nextPage();
        }
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

class _UserCommentsList extends StatefulWidget {
  const _UserCommentsList({required this.username});

  final String username;

  @override
  State<_UserCommentsList> createState() => _UserCommentsListState();
}

class _UserCommentsListState
    extends MultiPageLoadingState<_UserCommentsList, UserComment> {
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
  Widget buildContent(BuildContext context, List<UserComment> data) {
    return SliverList(
        delegate: SliverChildBuilderDelegate(
      (context, index) {
        if (index == data.length - 1) {
          nextPage();
        }
        return _UserCommentWidget(comment: data[index]);
      },
      childCount: data.length,
    ));
  }

  @override
  Future<Res<List<UserComment>>> loadData(int page) {
    return Network().getUserComment(widget.username, page);
  }
}

class _UserCommentWidget extends StatelessWidget {
  const _UserCommentWidget({required this.comment});

  final UserComment comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: context.colorScheme.outlineVariant, width: 0.4))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(comment.comment.content),
          const SizedBox(
            height: 8,
          ),
          InkWell(
            onTap: () {
              context.to('/post/${comment.memo.id}', {
                'memo': comment.memo,
              });
            },
            child: Container(
              padding: const EdgeInsets.only(top: 8, left: 8, bottom: 8),
              decoration: BoxDecoration(
                  border: Border(
                      left: BorderSide(
                          color: context.colorScheme.primary, width: 2))),
              child: Column(
                children: [
                  Row(
                    children: [
                      Avatar(
                        url: comment.memo.author!.avatar,
                        size: 24,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Text(comment.memo.author!.nickname),
                    ],
                  ),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    width: double.infinity,
                    child: ScrollConfiguration(
                      behavior:
                          const ScrollBehavior().copyWith(scrollbars: false),
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: MemoContent(
                            content: comment.memo.content.limitLine(5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).paddingLeft(8),
          const SizedBox(
            height: 8,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                comment.comment.date.toCompareString(),
                style: ts.s12.withColor(context.colorScheme.outline),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _UserLikedMemosList extends StatefulWidget {
  const _UserLikedMemosList({required this.username});

  final String username;

  @override
  State<_UserLikedMemosList> createState() => _UserLikedMemosListState();
}

class _UserLikedMemosListState
    extends MultiPageLoadingState<_UserLikedMemosList, Memo> {
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
        return MemoWidget(memo: data[index]);
      },
      childCount: data.length,
    ));
  }

  @override
  Future<Res<List<Memo>>> loadData(int page) {
    return Network().getUserLikedMemos(widget.username, page);
  }
}

class _UserStats extends StatefulWidget {
  const _UserStats({required this.user});

  final User user;

  @override
  State<_UserStats> createState() => _UserStatsState();
}

class _UserStatsState extends LoadingState<_UserStats, HeatMapData> {
  @override
  Widget buildLoading() {
    return SliverToBoxAdapter(
      child: Center(
        child: const CircularProgressIndicator(
          strokeWidth: 2,
        ).fixWidth(18).fixHeight(18),
      ).fixHeight(64),
    );
  }

  @override
  Widget buildError() {
    return SliverToBoxAdapter(
      child: super.buildError(),
    );
  }

  @override
  Widget buildContent(BuildContext context, HeatMapData data) {
    return SliverMainAxisGroup(slivers: [
      SliverToBoxAdapter(
        child: ListTile(
          title: Text(
              "{0} posts in the past year".tlParams([data.dailyData.length])),
        ),
      ),
      SliverToBoxAdapter(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: ScrollController(initialScrollOffset: 850),
          child: HeatMap(
            showStatistics: false,
            data: data,
          ).fixWidth(850).paddingHorizontal(16),
        ),
      ).sliverPadding(const EdgeInsets.only(bottom: 12)),
      SliverToBoxAdapter(
        child: ListTile(
          title: Text("Registered at".tl),
          subtitle: Text(widget.user.createdAt.toString().substring(0, 10)),
        ),
      ),
      SliverToBoxAdapter(
        child: ListTile(
          title: Text("Total posts".tl),
          subtitle: Text(widget.user.totalPosts.toString()),
        ),
      ),
      SliverToBoxAdapter(
        child: ListTile(
          title: Text("Total likes".tl),
          subtitle: Text(widget.user.totalLiked.toString()),
        ),
      ),
      SliverToBoxAdapter(
        child: ListTile(
          title: Text("Total comments".tl),
          subtitle: Text(widget.user.totalComment.toString()),
        ),
      ),
    ]);
  }

  @override
  Future<Res<HeatMapData>> loadData() {
    return Network().getHeatMapData(widget.user.username);
  }
}
