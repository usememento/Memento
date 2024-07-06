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
