import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:frontend/foundation/app.dart';

class Frame extends StatefulWidget {
  const Frame(this.child, this.naviObserver, {super.key});

  final NaviObserver naviObserver;

  final Widget child;

  @override
  State<Frame> createState() => _FrameState();
}

class _FrameState extends State<Frame> {
  late NaviObserver naviObserver;

  String path = "/";

  @override
  void initState() {
    naviObserver = widget.naviObserver;
    widget.naviObserver.addListener(onNavigation);
    super.initState();
  }

  @override
  void dispose() {
    widget.naviObserver.removeListener(onNavigation);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    if (naviObserver != widget.naviObserver) {
      naviObserver.removeListener(onNavigation);
      naviObserver = widget.naviObserver;
      naviObserver.addListener(onNavigation);
    }
    super.didChangeDependencies();
  }

  void onNavigation() {
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        path = naviObserver.routes.lastOrNull?.settings.name ?? "unknown";
      });
    });
  }

  static const _kSideBarWidth = 256.0;

  static const _kSmallSideBarWidth = 72.0;

  static const _kPhoneMaxWidth = 500.0;

  static const _kMinBodyWidth = 300.0;

  static const routes = {
    "Home": "/",
    "Explore": "/explore",
    "Archives": "/archives",
    "Settings": "/settings"
  };

  bool get isRoot => routes.values.contains(path);

  static const icons = {
    "Home": Icons.home_outlined,
    "Explore": Icons.explore_outlined,
    "Archives": Icons.folder_outlined,
    "Settings": Icons.settings_outlined
  };

  static const iconsActive = {
    "Home": Icons.home,
    "Explore": Icons.explore,
    "Archives": Icons.folder,
    "Settings": Icons.settings
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: LayoutBuilder(
          builder: (context, constrains) {
            var width = constrains.maxWidth;
            bool showFullSideBar = width >= _kSideBarWidth * 2 + _kMinBodyWidth;
            bool showSmallSideBar = !showFullSideBar && width > _kPhoneMaxWidth;
            bool showMobileUI = width <= _kPhoneMaxWidth;
            return Stack(
              children: [
                Positioned(
                  left: showFullSideBar
                      ? _kSideBarWidth
                      : (showSmallSideBar ? _kSmallSideBarWidth : 0),
                  right: showFullSideBar ? _kSideBarWidth : 0,
                  top: 0,
                  bottom: 0,
                  child: ClipRect(
                    child: widget.child,
                  ),
                ),
                if (showMobileUI)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    left: 0,
                    top: isRoot ? 0 : -58,
                    right: 0,
                    child: buildTop(),
                  ),
                if (showMobileUI)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    left: 0,
                    bottom: isRoot ? 0 : -64,
                    right: 0,
                    child: buildBottom(),
                  ),
                if (showFullSideBar)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: buildLeftFull(),
                  ),
                if (showSmallSideBar)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: buildLeftSmall(),
                  ),
                if (showFullSideBar)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: buildRightFull(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void to(String path) {
    var current = naviObserver.routes.lastOrNull?.settings.name ?? "unknown";
    if (current == path) return;
    App.navigatorState?.pushNamedAndRemoveUntil(path, (route) => false);
  }

  Widget buildLeftFull() {
    Widget buildItem(String name) {
      bool isActive = path == routes[name];
      return GestureDetector(
        onTap: () {
          setState(() {
            path = routes[name]!;
          });
          to(routes[name]!);
        },
        child: HoverBox(
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            key: ValueKey(name),
            duration: const Duration(milliseconds: 200),
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Icon(isActive ? iconsActive[name] : icons[name]),
                const SizedBox(
                  width: 12,
                ),
                Text(name)
              ],
            ),
          ),
        ),
      ).paddingVertical(4);
    }

    return Container(
      key: const ValueKey("left"),
      decoration: BoxDecoration(
        border: Border(
            right: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 0.6)),
      ),
      child: SizedBox(
        width: _kSideBarWidth,
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: routes.keys.map((e) => buildItem(e)).toList(),
          ),
        ),
      ).paddingHorizontal(8),
    );
  }

  Widget buildRightFull() {
    // TODO: show statistics
    return Container(
      key: const ValueKey("right"),
      decoration: BoxDecoration(
        border: Border(
            left: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 0.6)),
      ),
      child: const SizedBox(
        width: _kSideBarWidth,
        height: double.infinity,
        child: Text("Right"),
      ),
    );
  }

  Widget buildLeftSmall() {
    Widget buildItem(String name) {
      bool isActive = path == routes[name];
      return GestureDetector(
        onTap: () {
          setState(() {
            path = routes[name]!;
          });
          to(routes[name]!);
        },
        child: HoverBox(
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            key: ValueKey(name),
            duration: const Duration(milliseconds: 200),
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                borderRadius: BorderRadius.circular(16)),
            child: Icon(isActive ? iconsActive[name] : icons[name]),
          ),
        ),
      ).paddingVertical(4);
    }

    return Container(
      key: const ValueKey("left"),
      decoration: BoxDecoration(
        border: Border(
            right: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 0.6)),
      ),
      child: SizedBox(
        width: _kSmallSideBarWidth,
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: routes.keys.map((e) => buildItem(e)).toList(),
          ),
        ),
      ).paddingHorizontal(4),
    );
  }

  Widget buildTop() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 0.6)),
      ),
      width: double.infinity,
      height: 58 + context.padding.bottom,
      child: Padding(
        padding: EdgeInsets.only(bottom: context.padding.bottom),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                // TODO: show drawer
              },
            ),
            const Spacer(),
            const Text("Memento"),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
            ),
          ],
        ).paddingHorizontal(16),

      ),
    );
  }

  Widget buildBottom() {
    Widget buildItem(String name) {
      bool isActive = path == routes[name];
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              path = routes[name]!;
            });
            to(routes[name]!);
          },
          child: HoverBox(
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              key: ValueKey(name),
              width: 48,
              height: 48,
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(isActive ? iconsActive[name] : icons[name]).toCenter(),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 64,
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 0.6)),
      ),
      child: Row(
        children: routes.keys.map((e) => buildItem(e)).toList(),
      ),
    );
  }
}

class NaviObserver extends NavigatorObserver implements Listenable {
  var routes = Queue<Route>();

  int get pageCount => routes.length;

  @override
  void didPop(Route route, Route? previousRoute) {
    routes.removeLast();
    notifyListeners();
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    routes.addLast(route);
    notifyListeners();
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    routes.remove(route);
    notifyListeners();
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    routes.remove(oldRoute);
    if (newRoute != null) {
      routes.add(newRoute);
    }
    notifyListeners();
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

class HoverBox extends StatefulWidget {
  const HoverBox(
      {super.key, required this.child, this.borderRadius = BorderRadius.zero});

  final Widget child;

  final BorderRadius borderRadius;

  @override
  State<HoverBox> createState() => _HoverBoxState();
}

class _HoverBoxState extends State<HoverBox> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHover = true),
      onExit: (_) => setState(() => isHover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
            color: isHover
                ? Theme.of(context).colorScheme.surfaceContainerHigh
                : null,
            borderRadius: widget.borderRadius),
        child: widget.child,
      ),
    );
  }
}
