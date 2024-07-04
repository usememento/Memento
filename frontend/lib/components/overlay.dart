import 'package:flutter/material.dart';
import 'package:frontend/foundation/app.dart';

class OverlayWidget extends StatefulWidget {
  const OverlayWidget(this.child, {super.key});

  final Widget child;

  static OverlayWidgetState of(BuildContext context) {
    return context.findAncestorStateOfType<OverlayWidgetState>()!;
  }

  @override
  State<OverlayWidget> createState() => OverlayWidgetState();
}

class OverlayWidgetState extends State<OverlayWidget> {
  var overlayKey = GlobalKey<OverlayState>();

  var entries = <OverlayEntry>[];

  void addOverlay(OverlayEntry entry) {
    if (overlayKey.currentState != null) {
      overlayKey.currentState!.insert(entry);
      entries.add(entry);
    }
  }

  void remove(OverlayEntry entry) {
    if (entries.remove(entry)) {
      entry.remove();
    }
  }

  void showMessage(String message, {Widget? trailing, Widget? leading}) {
    var controller = _MessageOverlayController();
    var overlay = _MessageOverlay(message, trailing, leading, controller);
    var entry = OverlayEntry(builder: (context) => overlay);
    addOverlay(entry);
    Future.delayed(const Duration(seconds: 3), () {
      controller.reverseAnimation!().then((value) {
        remove(entry);
      });
    });
  }

  void showError(String message) {
    showMessage(message, leading: const Icon(Icons.error_outline, color: Colors.red));
  }

  void removeAll() {
    for (var entry in entries) {
      entry.remove();
    }
    entries.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(
      key: overlayKey,
      initialEntries: [OverlayEntry(builder: (context) => widget.child)],
    );
  }
}

class _MessageOverlayController {
  Future Function()? reverseAnimation;

  _MessageOverlayController();
}

class _MessageOverlay extends StatefulWidget {
  const _MessageOverlay(this.message, this.trailing, this.leading, this.controller);

  final String message;
  final Widget? trailing;
  final Widget? leading;
  final _MessageOverlayController controller;

  @override
  State<_MessageOverlay> createState() => _MessageOverlayState();
}

class _MessageOverlayState extends State<_MessageOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 160));
    _controller.forward();
    widget.controller.reverseAnimation = () {
      return _controller.reverse();
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var padding = context.width - 400;
    if (padding < 32) {
      padding = 32;
    }
    return AnimatedBuilder(
        animation: CurvedAnimation(parent: _controller, curve: Curves.ease),
        builder: (context, child) => Positioned(
              bottom: (24 + MediaQuery.of(context).viewInsets.bottom) *
                  (_controller.value * 2 - 1),
              left: padding / 2,
              right: padding / 2,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints:
                      const BoxConstraints(minHeight: 48, maxHeight: 104),
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        blurRadius: 4,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                      ),
                      if (widget.leading != null) widget.leading!,
                      const SizedBox(width: 8,),
                      Expanded(
                          child: Text(
                        widget.message,
                        maxLines: 3,
                      )),
                      if (widget.trailing != null) widget.trailing!,
                      const SizedBox(
                        width: 8,
                      )
                    ],
                  ),
                ),
              ),
            ));
  }
}
