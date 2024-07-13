import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/utils/translation.dart';

import '../network/network.dart';
import 'button.dart';

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.url, this.size = 40.0});

  final String url;

  final double size;

  @override
  Widget build(BuildContext context) {
    var url = this.url;
    if(url != "") {
      url = appdata.settings['domain'] + '/api/user/avatar/' + url;
    }
    ImageProvider image =
        App.isWeb ? NetworkImage(url) : CachedNetworkImageProvider(url);
    var defaultAvatar = 'assets/user.png';
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image(
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        image: image,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(defaultAvatar, fit: BoxFit.cover);
        },
      ),
    );
  }
}

class UserCard extends StatefulWidget {
  const UserCard({super.key, required this.user});

  final User user;

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  bool isFollowing = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          context.to('/user/${widget.user.username}');
        },
        child: SizedBox(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(
                url: widget.user.avatar,
                size: 38,
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.user.nickname,
                          style: ts.bold.s16,
                        ),
                        const Spacer(),
                        if (appdata.isLogin && widget.user.username != appdata.user.username)
                          Button.outlined(
                              width: widget.user.isFollowed ? 84 : 72,
                              height: 24,
                              padding: EdgeInsets.zero,
                              isLoading: isFollowing,
                              onPressed: follow,
                              color: widget.user.isFollowed ? Colors.red : null,
                              child: widget.user.isFollowed
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
                    Text(
                      "@${widget.user.username}",
                      style: ts.s12,
                    ),
                    if (widget.user.bio.isNotEmpty)
                      Text(
                        widget.user.bio,
                        maxLines: 3,
                      ),
                  ],
                ),
              ),
            ],
          ).paddingHorizontal(16).paddingVertical(8),
        ));
  }

  void follow() async {
    setState(() {
      isFollowing = true;
    });
    var res = await Network()
        .followOrUnfollow(widget.user.username, !widget.user.isFollowed);
    if (mounted) {
      if (res.success) {
        setState(() {
          isFollowing = false;
          widget.user.isFollowed = !widget.user.isFollowed;
          widget.user.totalFollower += widget.user.isFollowed ? 1 : -1;
        });
      } else {
        setState(() {
          isFollowing = false;
        });
        context.showMessage(res.message);
      }
    }
  }
}
