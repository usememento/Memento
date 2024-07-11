import 'dart:math';

import 'package:flutter/material.dart';
import 'package:frontend/components/button.dart';
import 'package:frontend/foundation/app.dart';

Future<T?> pushDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return Navigator.of(context).push<T>(PageRouteBuilder(
    opaque: false,
    fullscreenDialog: true,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.2),
    pageBuilder: (context, animation, secondaryAnimation) {
      return FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1)
            .animate(CurvedAnimation(parent: animation, curve: Curves.ease)),
        child: Center(
          child: builder(context),
        ),
      );
    },
  ));
}

class DialogContent extends StatelessWidget {
  const DialogContent(
      {super.key, required this.title, this.body, this.actions = const []});

  final String title;

  final Widget? body;

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: IntrinsicWidth(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: min(600, context.width - 32),
            minWidth: min(342, context.width - 32),
          ),
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Button.icon(
                    icon: const Icon(Icons.close),
                    color: context.colorScheme.onSurface,
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: ts.s18.bold,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (body != null) body!,
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
