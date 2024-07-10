import 'package:flutter/material.dart';
import 'package:frontend/foundation/app.dart';

class Appbar extends StatelessWidget {
  const Appbar(
      {super.key,
      required this.title,
      this.actions = const [],
      this.removePadding = false,
      this.color,
      this.primary = true});

  final String title;

  final List<Widget> actions;

  final bool primary;

  final bool removePadding;

  final Color? color;

  static const _kAppBarHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? context.colorScheme.surface,
      child: Row(
        children: [
          if (Navigator.of(context).canPop())
            Tooltip(
              message: "Back",
              child: IconButton(
                icon: const Icon(Icons.arrow_back_sharp),
                onPressed: () {
                  context.pop();
                },
              ),
            ),
          if (Navigator.of(context).canPop()) const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
              ),
            ),
          ),
          ...actions,
        ],
      )
          .fixHeight(_kAppBarHeight)
          .paddingTop(primary ? context.padding.top : 0)
          .paddingHorizontal(removePadding ? 0 : 8),
    );
  }
}

class SliverAppbar extends StatelessWidget {
  const SliverAppbar(
      {super.key,
      required this.title,
      this.actions = const [],
      this.removePadding = false,
      this.color,
      this.primary = true});

  final Widget title;

  final List<Widget> actions;

  final bool primary;

  final bool removePadding;

  final Color? color;

  static const _kAppBarHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
        pinned: true,
        delegate: SliverPersistentTopDelegate(
            height: _kAppBarHeight + (primary ? context.padding.top : 0),
          builder: (context) {
            return Material(
              color: color ?? context.colorScheme.surface,
              child: Row(
                children: [
                  if (Navigator.of(context).canPop())
                    Tooltip(
                      message: "Back",
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_sharp),
                        onPressed: () {
                          context.pop();
                        },
                      ),
                    ),
                  if (Navigator.of(context).canPop()) const SizedBox(width: 8),
                  Expanded(
                    child: DefaultTextStyle(
                      style: DefaultTextStyle.of(context).style.s20,
                      child: title,
                    ),
                  ),
                  ...actions,
                ],
              )
                  .fixHeight(_kAppBarHeight)
                  .paddingTop(primary ? context.padding.top : 0)
                  .paddingHorizontal(removePadding ? 0 : 8),
            );
          }
        ));
  }
}

class SliverPersistentTopDelegate extends SliverPersistentHeaderDelegate {
  const SliverPersistentTopDelegate({
    required this.height,
    required this.builder,
  });

  final double height;

  final WidgetBuilder builder;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return builder(context);
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
