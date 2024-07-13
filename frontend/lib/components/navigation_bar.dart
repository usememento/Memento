import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../foundation/app.dart';

class PaneItemEntry {
  String label;

  IconData icon;

  IconData activeIcon;

  String routeName;

  PaneItemEntry(
      {required this.label,
      required this.icon,
      required this.activeIcon,
      required this.routeName});
}

class PaneActionEntry {
  String label;

  IconData icon;

  VoidCallback onTap;

  String? routeName;

  PaneActionEntry(
      {required this.label,
      required this.icon,
      required this.onTap,
      this.routeName});
}

class NaviPaneLeading {
  final Widget large;
  final Widget small;

  NaviPaneLeading({
    required this.large,
    required this.small,
  });
}

class NaviPane extends StatefulWidget {
  const NaviPane(
      {required this.paneItems,
      required this.paneActions,
      required this.pageBuilder,
      this.initialPage = 0,
      this.onPageChange,
      this.leading,
      required this.observer,
      super.key});

  final List<PaneItemEntry> paneItems;

  final List<PaneActionEntry> paneActions;

  final Widget Function(int page) pageBuilder;

  final void Function(int index)? onPageChange;

  final int initialPage;

  final NaviObserver observer;

  final NaviPaneLeading? leading;

  @override
  State<NaviPane> createState() => _NaviPaneState();
}

class _NaviPaneState extends State<NaviPane>
    with SingleTickerProviderStateMixin {
  late int _currentPage = widget.initialPage;

  int get currentPage => _currentPage;

  set currentPage(int value) {
    if (value == _currentPage && widget.observer.routes.length == 1) return;
    _currentPage = value;
    widget.onPageChange?.call(value);
  }

  late AnimationController controller;

  static const _kChangePoint = 600.0;

  static const _kChangePoint2 = 1200.0;

  static const _kBottomBarHeight = 64.0;

  static const _kFoldedSideBarWidth = 72.0;

  static const _kSideBarWidth = 284.0;

  static const _kTopBarHeight = 56.0;

  double get bottomBarHeight =>
      _kBottomBarHeight + MediaQuery.of(context).padding.bottom;

  void onNavigatorStateChange() {
    Future.microtask(() => setState(() {}));
  }

  @override
  void initState() {
    controller = AnimationController(
        duration: const Duration(milliseconds: 250),
        lowerBound: 0,
        upperBound: 3,
        vsync: this);
    widget.observer.addListener(onNavigatorStateChange);
    super.initState();
  }

  bool isInitial = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!isInitial) {
      controller.value = targetFromContext(context);
      isInitial = true;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    widget.observer.removeListener(onNavigatorStateChange);
    super.dispose();
  }

  double? animationTarget;

  double targetFromContext(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    double target = 0;
    if (widget.observer.pageCount > 1) {
      target = 1;
    }
    if (width > _kChangePoint) {
      target = 2;
    }
    if (width > _kChangePoint2) {
      target = 3;
    }
    return target;
  }

  void onRebuild(BuildContext context) {
    double target = targetFromContext(context);

    if (controller.value != target || animationTarget != target) {
      if (controller.isAnimating) {
        if (animationTarget == target) {
          return;
        } else {
          controller.stop();
        }
      }
      controller.animateTo(target,
          duration: const Duration(milliseconds: 160), curve: Curves.ease);
      animationTarget = target;
    }
  }

  @override
  Widget build(BuildContext context) {
    onRebuild(context);
    return _NaviPopScope(
      action: () {
        if (widget.observer.navigator!.canPop()) {
          widget.observer.navigator!.pop();
        } else {
          SystemNavigator.pop();
        }
      },
      popGesture: App.isIOS && context.width > _kChangePoint,
      child: Material(
        color: context.colorScheme.surface,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final value = controller.value;
            return Stack(
              children: [
                Positioned(
                  top: _kTopBarHeight * ((1 - value).clamp(0, 1)) +
                      MediaQuery.of(context).padding.top *
                          ((1 - value).clamp(0, 1)),
                  left: _kFoldedSideBarWidth * ((value - 1).clamp(0, 1)) +
                      (_kSideBarWidth - _kFoldedSideBarWidth) *
                          ((value - 2).clamp(0, 1)),
                  right: 0,
                  bottom: bottomBarHeight * ((1 - value).clamp(0, 1)),
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: value == 0,
                    child: widget.pageBuilder(currentPage),
                  ),
                ),
                if (value <= 1)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: bottomBarHeight * (0 - value),
                    child: buildBottom(),
                  ),
                if (value <= 1)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: _kTopBarHeight * (0 - value) +
                        MediaQuery.of(context).padding.top * (1 - value),
                    child: buildTop(),
                  ),
                Positioned(
                  left: _kFoldedSideBarWidth * ((value - 2.0).clamp(-1.0, 0.0)),
                  top: 0,
                  bottom: 0,
                  child: buildLeft(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget buildTop() {
    return Material(
      color: context.colorScheme.surface,
      shape: Border(
          bottom: BorderSide(
              color: context.colorScheme.outlineVariant, width: 0.6)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        height: _kTopBarHeight,
        width: double.infinity,
        child: Row(
          children: [
            if (widget.leading != null) widget.leading!.small,
            if (widget.leading != null)
              const SizedBox(
                width: 12,
              ),
            Text(
              widget.paneItems[currentPage].label,
              style: const TextStyle(fontSize: 18),
            ),
            const Spacer(),
            for (var action in widget.paneActions)
              Tooltip(
                message: action.label,
                child: IconButton(
                  icon: Icon(action.icon),
                  onPressed: action.onTap,
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget buildBottom() {
    return Material(
        textStyle: Theme.of(context).textTheme.labelSmall,
        color: context.colorScheme.surface,
        shape: Border(
            top: BorderSide(
                color: context.colorScheme.outlineVariant, width: 0.6)),
        child: SizedBox(
          height: _kBottomBarHeight + MediaQuery.of(context).padding.bottom,
          child: Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            child: Row(
              children: List<Widget>.generate(
                  widget.paneItems.length,
                  (index) => Expanded(
                          child: _SingleBottomNaviWidget(
                        enabled: currentPage == index,
                        entry: widget.paneItems[index],
                        onTap: () {
                          setState(() {
                            currentPage = index;
                          });
                        },
                        key: ValueKey(index),
                      ))),
            ),
          ),
        ));
  }

  Widget buildLeft() {
    final value = controller.value;
    var padding = value == 3 ? 16.0 : 12.0;
    return Material(
      color: context.colorScheme.surface,
      child: Container(
        width: _kFoldedSideBarWidth +
            (_kSideBarWidth - _kFoldedSideBarWidth) *
                ((value - 2).clamp(0, 1)) +
            0.6,
        height: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: padding),
        decoration: BoxDecoration(
            border: Border(
                right: BorderSide(
                    color: context.colorScheme.outlineVariant, width: 0.6))),
        child: Row(
          children: [
            SizedBox(
              width: value == 3
                  ? (_kSideBarWidth - padding * 2)
                  : (_kFoldedSideBarWidth - padding * 2),
              child: Column(
                children: [
                  const SizedBox(
                    height: 16,
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).padding.top,
                  ),
                  if (widget.leading != null)
                    if (value == 3)
                      widget.leading!.large
                    else
                      widget.leading!.small,
                  const SizedBox(
                    height: 16,
                  ),
                  ...List<Widget>.generate(
                      widget.paneItems.length,
                      (index) => _SideNaviWidget(
                            enabled: widget.observer.currentRoute ==
                                widget.paneItems[index].routeName,
                            entry: widget.paneItems[index],
                            showTitle: value == 3,
                            onTap: () {
                              setState(() {
                                currentPage = index;
                              });
                            },
                            key: ValueKey(index),
                          )),
                  const Spacer(),
                  ...List<Widget>.generate(
                      widget.paneActions.length,
                      (index) => _PaneActionWidget(
                            isActive: widget.observer.currentRoute ==
                                widget.paneActions[index].routeName,
                            entry: widget.paneActions[index],
                            showTitle: value == 3,
                            key: ValueKey(index + widget.paneItems.length),
                          )),
                  const SizedBox(
                    height: 16,
                  )
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _SideNaviWidget extends StatefulWidget {
  const _SideNaviWidget(
      {required this.enabled,
      required this.entry,
      required this.onTap,
      required this.showTitle,
      super.key});

  final bool enabled;

  final PaneItemEntry entry;

  final VoidCallback onTap;

  final bool showTitle;

  @override
  State<_SideNaviWidget> createState() => _SideNaviWidgetState();
}

class _SideNaviWidgetState extends State<_SideNaviWidget> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon =
        Icon(widget.enabled ? widget.entry.activeIcon : widget.entry.icon);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (details) => setState(() => isHovering = true),
      onExit: (details) => setState(() => isHovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTap,
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            width: double.infinity,
            height: 42,
            decoration: BoxDecoration(
                color: widget.enabled
                    ? colorScheme.primaryContainer
                    : isHovering
                        ? colorScheme.surfaceContainerHigh
                        : null,
                borderRadius: BorderRadius.circular(4)),
            child: widget.showTitle
                ? Row(
                    children: [
                      icon,
                      const SizedBox(
                        width: 12,
                      ),
                      Text(widget.entry.label)
                    ],
                  )
                : Center(
                    child: icon,
                  )),
      ),
    );
  }
}

class _PaneActionWidget extends StatefulWidget {
  const _PaneActionWidget(
      {required this.entry,
      required this.showTitle,
      required this.isActive,
      super.key});

  final PaneActionEntry entry;

  final bool showTitle;

  final bool isActive;

  @override
  State<_PaneActionWidget> createState() => _PaneActionWidgetState();
}

class _PaneActionWidgetState extends State<_PaneActionWidget> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = Icon(widget.entry.icon);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (details) => setState(() => isHovering = true),
      onExit: (details) => setState(() => isHovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.isActive ? null : widget.entry.onTap,
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            width: double.infinity,
            height: 42,
            decoration: BoxDecoration(
                color: widget.isActive
                    ? colorScheme.primaryContainer
                    : isHovering
                        ? colorScheme.surfaceContainerHigh
                        : null,
                borderRadius: BorderRadius.circular(4)),
            child: widget.showTitle
                ? Row(
                    children: [
                      icon,
                      const SizedBox(
                        width: 12,
                      ),
                      Text(widget.entry.label)
                    ],
                  )
                : Center(
                    child: icon,
                  )),
      ),
    );
  }
}

class _SingleBottomNaviWidget extends StatefulWidget {
  const _SingleBottomNaviWidget(
      {required this.enabled,
      required this.entry,
      required this.onTap,
      super.key});

  final bool enabled;

  final PaneItemEntry entry;

  final VoidCallback onTap;

  @override
  State<_SingleBottomNaviWidget> createState() =>
      _SingleBottomNaviWidgetState();
}

class _SingleBottomNaviWidgetState extends State<_SingleBottomNaviWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  bool isHovering = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _SingleBottomNaviWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        controller.forward(from: 0);
      } else {
        controller.reverse(from: 1);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        value: widget.enabled ? 1 : 0,
        vsync: this,
        duration: const Duration(milliseconds: 150));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (details) => setState(() => isHovering = true),
          onExit: (details) => setState(() => isHovering = false),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onTap,
            child: buildContent(),
          ),
        );
      },
    );
  }

  Widget buildContent() {
    final value = controller.value;
    final colorScheme = Theme.of(context).colorScheme;
    final icon =
        Icon(widget.enabled ? widget.entry.activeIcon : widget.entry.icon);
    return SizedBox(
      child: Center(
        child: SizedBox(
          width: 80,
          height: 68,
          child: Stack(
            children: [
              Positioned(
                top: 10 * value,
                left: 0,
                right: 0,
                bottom: 28 * value,
                child: Center(
                  child: Container(
                    width: 64,
                    height: 28,
                    decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(32)),
                        color: value != 0
                            ? colorScheme.primaryContainer
                            : (isHovering
                                ? colorScheme.surfaceContainerHighest
                                : null)),
                    child: Center(child: icon),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                bottom: 4,
                child: Center(
                  child: Opacity(
                    opacity: value,
                    child: Text(widget.entry.label),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NaviObserver extends NavigatorObserver implements Listenable {
  var routes = Queue<Route>();

  int get pageCount => routes.length;

  String? get currentRoute => routes.lastOrNull?.settings.name;

  @override
  void didPop(Route route, Route? previousRoute) {
    routes.removeLast();
    notifyListeners();
    debugPrint("Pop route ${route.settings.name}");
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    routes.addLast(route);
    notifyListeners();
    debugPrint("Going to route ${route.settings.name}");
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    routes.remove(route);
    notifyListeners();
    debugPrint("Remove route ${route.settings.name}");
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    routes.remove(oldRoute);
    if (newRoute != null) {
      routes.add(newRoute);
    }
    notifyListeners();
    debugPrint(
        "Replace route ${oldRoute?.settings.name} with ${newRoute?.settings.name}");
  }

  List<VoidCallback> listeners = [];

  @override
  void addListener(VoidCallback listener) {
    listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listeners.remove(listener);
  }

  void notifyListeners() {
    for (var listener in listeners) {
      listener();
    }
  }
}

class _NaviPopScope extends StatelessWidget {
  const _NaviPopScope(
      {required this.child, this.popGesture = false, required this.action});

  final Widget child;
  final bool popGesture;
  final VoidCallback action;

  static bool panStartAtEdge = false;

  @override
  Widget build(BuildContext context) {
    Widget res = App.isIOS
        ? child
        : PopScope(
            canPop: App.isAndroid ? false : true,
            onPopInvoked: (value) {
              action();
            },
            child: child);
    if (popGesture) {
      res = GestureDetector(
          onPanStart: (details) {
            if (details.globalPosition.dx < 64) {
              panStartAtEdge = true;
            }
          },
          onPanEnd: (details) {
            if (details.velocity.pixelsPerSecond.dx < 0 ||
                details.velocity.pixelsPerSecond.dx > 0) {
              if (panStartAtEdge) {
                action();
              }
            }
            panStartAtEdge = false;
          },
          child: res);
    }
    return res;
  }
}
