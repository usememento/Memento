import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/components/heat_map.dart';
import 'package:frontend/components/user.dart';
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

  static const _kSideBarWidth = 284.0;

  static const _kSmallSideBarWidth = 72.0;

  static const _kPhoneMaxWidth = 500.0;

  static const _kMinBodyWidth = 400.0;

  static const _kDrawerWidth = 256.0;

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
    "Settings": Icons.settings_outlined,
    "Search": Icons.search_outlined,
  };

  static const iconsActive = {
    "Home": Icons.home,
    "Explore": Icons.explore,
    "Archives": Icons.folder,
    "Settings": Icons.settings,
    "Search": Icons.search,
  };

  bool isDrawerOpen = false;

  @override
  Widget build(BuildContext context) {
    appdata.useTestUser();
    var body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
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
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: !isDrawerOpen,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isDrawerOpen = false;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        color: Colors.black.withOpacity(0.3 * (isDrawerOpen ? 1 : 0))
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  left: isDrawerOpen ? 0 : -_kDrawerWidth,
                  top: 0,
                  bottom: 0,
                  child: buildSideBar(),
                ),
              ],
            );
          },
        ),
      ),
    );

    return _NaviPopScope(
      popGesture: true,
      action: () {
        if (naviObserver.routes.length > 1) {
          App.navigatorState?.pop();
        } else {
          SystemNavigator.pop();
        }
      },
      child: body,
    );
  }

  void to(String path, [Object? arguments]) {
    var current = naviObserver.routes.lastOrNull?.settings.name ?? "unknown";
    if (current == path) return;
    App.navigatorState?.pushNamed(path, arguments: arguments);
  }

  void toAndRemoveAll(String path) {
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
          toAndRemoveAll(routes[name]!);
        },
        child: HoverBox(
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            key: ValueKey(name),
            duration: const Duration(milliseconds: 200),
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                borderRadius: BorderRadius.circular(8)),
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
                width: 0.4)),
      ),
      child: SizedBox(
        width: _kSideBarWidth - 32,
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children:[
              HoverBox(
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Avatar(url: appdata.user.avatar, size: 36,),
                    const SizedBox(width: 12,),
                    Text(appdata.user.name),
                  ],
                ).paddingHorizontal(8).paddingVertical(8),
              ).onTap(() {
                to("/user");
              }),
              const SizedBox(height: 16,),
              ...routes.keys.map((e) => buildItem(e))
            ],
          ),
        ),
      ).paddingHorizontal(16),
    );
  }

  Widget buildRightFull() {
    return Container(
      key: const ValueKey("right"),
      decoration: BoxDecoration(
        border: Border(
            left: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 0.4)),
      ),
      child: SizedBox(
        width: _kSideBarWidth - 32,
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Container(
                height: 42,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: "Search",
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (s) {
                    to("/search", {
                      "keyword": s,
                    });
                  },
                ),
              ),
              const SizedBox(height: 16,),
              HeatMap(data: getTestData())
            ],
          ),
        ),
      ).paddingHorizontal(16),
    );
  }

  Widget buildLeftSmall() {
    Widget buildItem(String name, [String? routePath]) {
      bool isActive = path == (routePath ?? routes[name]);
      return GestureDetector(
        onTap: () {
          setState(() {
            path = routePath ?? routes[name]!;
          });
          toAndRemoveAll(routePath ?? routes[name]!);
        },
        child: HoverBox(
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            key: ValueKey(name),
            duration: const Duration(milliseconds: 200),
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                borderRadius: BorderRadius.circular(8)),
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
                width: 0.4)),
      ),
      child: SizedBox(
        width: _kSmallSideBarWidth,
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              HoverBox(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 48,
                  width: 56,
                  child: Avatar(url: appdata.user.avatar, size: 36,).toCenter(),
                ),
              ).onTap(() {
                to("/user");
              }),
              const SizedBox(height: 16,),
              ...routes.keys.map((e) => buildItem(e)),
              buildItem("Search", "/search"),
            ],
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
                width: 0.4)),
      ),
      width: double.infinity,
      height: 58 + context.padding.bottom,
      child: Padding(
        padding: EdgeInsets.only(bottom: context.padding.bottom),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  isDrawerOpen = !isDrawerOpen;
                });
              },
              child: HoverBox(
                borderRadius: BorderRadius.circular(36),
                child: Avatar(url: appdata.user.avatar, size: 36,),
              ),
            ),
            const Spacer(),
            const Text("Memento"),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                to("/search");
              },
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
            toAndRemoveAll(routes[name]!);
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
                width: 0.4)),
      ),
      child: Row(
        children: routes.keys.map((e) => buildItem(e)).toList(),
      ),
    );
  }

  Widget buildSideBar() {
    return Container(
      width: _kDrawerWidth,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16,),
          HoverBox(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Avatar(url: appdata.user.avatar, size: 36,),
                const SizedBox(width: 12,),
                Text(appdata.user.name),
              ],
            ).paddingHorizontal(8).paddingVertical(8),
          ).onTap(() {
            setState(() {
              isDrawerOpen = false;
            });
            to("/user");
          }),
          const SizedBox(height: 8,),
          const Divider(height: 1,),
          const SizedBox(height: 8,),
          HeatMap(data: getTestData())
        ],
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

class _NaviPopScope extends StatelessWidget {
  const _NaviPopScope(
      {required this.child,
        this.popGesture = false,
        required this.action});

  final Widget child;
  final bool popGesture;
  final VoidCallback action;

  static bool panStartAtEdge = false;

  @override
  Widget build(BuildContext context) {
    Widget res = App.isIOS ? child : PopScope(
        canPop: App.isAndroid ? false : true,
        onPopInvoked: (value) {
          action();
        },
        child: child);
    if(popGesture){
      res = GestureDetector(
          onPanStart: (details){
            if(details.globalPosition.dx < 64){
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
