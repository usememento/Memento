import 'dart:math';

import 'package:flutter/material.dart';
import 'package:frontend/components/user.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/network/models.dart';
import 'package:frontend/utils/ext.dart';

import '../network/network.dart';
import 'button.dart';

class CommentsPageRoute extends PageRoute {
  CommentsPageRoute({required this.builder});

  final WidgetBuilder builder;

  @override
  Color? get barrierColor => Colors.black.withOpacity(0.4);

  @override
  String? get barrierLabel => null;

  @override
  bool get barrierDismissible => true;

  static const _kMaxWidth = 400.0;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.ease)),
      child: Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: context.colorScheme.surface,
          child: SizedBox(
            width: min(context.width, _kMaxWidth),
            height: double.infinity,
            child: builder(context),
          ),
        ),
      ),
    );
  }

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 250);

  @override
  bool get opaque => false;

  @override
  bool get fullscreenDialog => true;
}

class CommentWidget extends StatefulWidget {
  const CommentWidget({super.key, required this.comment});

  final Comment comment;

  @override
  State<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  Comment get comment => widget.comment;

  bool isLiking = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Avatar(
            url: comment.author.avatar,
            size: 32,
          ).paddingTop(4),
          const SizedBox(
            width: 4,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.author.nickname,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ).paddingLeft(8),
                Text(comment.content).paddingLeft(8).paddingVertical(4),
                Row(
                  children: [
                    Button.normal(
                      onPressed: like,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      isLoading: isLiking,
                      height: 36,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (comment.isLiked)
                            const Icon(Icons.favorite, size: 18, color: Colors.red)
                          else
                            const Icon(
                              Icons.favorite_border,
                              size: 18,
                            ),
                          const SizedBox(width: 4),
                          Text(
                            comment.likesCount.toString(),
                            style: const TextStyle(fontSize: 14),
                          ).paddingBottom(2),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      comment.date.toCompareString(),
                      style: TextStyle(
                        color: context.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ).paddingHorizontal(16).paddingVertical(8),
    );
  }

  void like() async {
    if (isLiking) return;
    setState(() {
      isLiking = true;
    });
    try {
      await Network().likeOrUnlikeComment(comment.id, !comment.isLiked);
      setState(() {
        comment.isLiked = !comment.isLiked;
        if (comment.isLiked) {
          comment.likesCount++;
        } else {
          comment.likesCount--;
        }
      });
    } finally {
      setState(() {
        isLiking = false;
      });
    }
  }
}
