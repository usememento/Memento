import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/button.dart';
import 'package:frontend/components/comments.dart';
import 'package:frontend/components/states.dart';
import 'package:frontend/components/user.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/network/network.dart';
import 'package:frontend/utils/translation.dart';

class CommentsPage extends StatefulWidget {
  const CommentsPage({super.key, required this.id});

  final int id;

  static void show(int id) {
    App.rootNavigatorKey!.currentState!.push(CommentsPageRoute(
      builder: (context) => CommentsPage(id: id),
    ));
  }

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  int commentsKey = 0;

  bool sending = false;

  var controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Appbar(
          title: 'Comments',
        ),
        Expanded(
          child: _CommentsList(
            widget.id,
            key: ValueKey(commentsKey),
          ),
        ),
        Container(
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16))),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: const BorderRadius.all(Radius.circular(32))),
                child: Row(
                  children: [
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                            hintText: "评论".tl),
                        minLines: 1,
                        maxLines: 5,
                        controller: controller,
                        onSubmitted: (text) {
                          onSend();
                        },
                      ),
                    )),
                    sending
                        ? const Padding(
                            padding: EdgeInsets.all(8.5),
                            child: SizedBox(
                              width: 23,
                              height: 23,
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : IconButton(
                            onPressed: onSend,
                            icon: const Icon(
                              Icons.send,
                            ))
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void onSend() async {
    setState(() {
      sending = true;
    });
    var res = await Network().sendComment(widget.id, controller.text);
    if (mounted) {
      if (res.success) {
        setState(() {
          commentsKey++;
          controller.clear();
          sending = false;
        });
      } else {
        context.showMessage(res.message);
        setState(() {
          sending = false;
        });
      }
    }
  }
}

class _CommentsList extends StatefulWidget {
  const _CommentsList(this.memoId, {super.key});

  final int memoId;

  @override
  State<_CommentsList> createState() => _CommentsListState();
}

class _CommentsListState extends MultiPageLoadingState<_CommentsList, Comment> {
  @override
  Widget buildContent(BuildContext context, List<Comment> data) {
    return ListView.builder(
      itemCount: data.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final comment = data[index];
        return CommentWidget(comment: comment);
      },
    );
  }

  void like() {}

  @override
  Future<Res<List<Comment>>> loadData(int page) {
    return Network().getComments(widget.memoId, page);
  }
}
