import 'package:flutter/material.dart';
import 'package:frontend/components/navigation_bar.dart';
import 'package:frontend/pages/page_404.dart';
import 'package:frontend/pages/settings_page.dart';
import 'package:frontend/pages/tagged_memos_list_page.dart';
import 'package:frontend/pages/user_page.dart';
import 'package:frontend/utils/translation.dart';

import '../components/button.dart';
import '../components/user.dart';
import '../foundation/app.dart';
import 'explore_page.dart';
import 'home_page.dart';
import 'memo_details_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  static Map<String, Widget Function(BuildContext context)> routes = {
    '/': (context) => const HomePage(),
    '/explore': (context) => const ExplorePage(),
    '/settings': (context) => const SettingsPage(),
    '/memo/:id': (context) => const MemoDetailsPage(),
    '/tag/:tag': (context) => const TaggedMemosListPage(),
    '/user/:username': (context) => const UserInfoPage(),
    '/user/:username/followers': (context) => UserListPage.followers(),
    '/user/:username/following': (context) => UserListPage.following(),
  };

  static const mainPageRoutes = [
    '/',
    '/explore',
    '/archives',
    '/resources',
    '/notifications',
  ];

  var observer = NaviObserver();

  @override
  void initState() {
    App.navigatorKey = GlobalKey();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1400),
      child: NaviPane(
        paneItems: [
          PaneItemEntry(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_filled,
            label: "Home",
            routeName: '/',
          ),
          PaneItemEntry(
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore,
            label: "Explore",
            routeName: '/explore',
          ),
          PaneItemEntry(
            icon: Icons.folder_outlined,
            activeIcon: Icons.folder,
            label: "Archives",
            routeName: '/archives',
          ),
          PaneItemEntry(
            icon: Icons.my_library_books_outlined,
            activeIcon: Icons.my_library_books,
            label: "Resources",
            routeName: '/resources',
          ),
          PaneItemEntry(
            icon: Icons.notifications_outlined,
            activeIcon: Icons.notifications,
            label: "Notifications",
            routeName: '/notifications',
          ),
        ],
        paneActions: [
          if (context.width <= 600)
            PaneActionEntry(label: "Search", icon: Icons.search, onTap: () {}),
          PaneActionEntry(
              routeName: '/settings',
              label: "Settings",
              icon: Icons.settings_outlined,
              onTap: () {
                App.navigatorState!.pushNamed('/settings');
              }),
        ],
        onPageChange: (index) {
          App.navigatorState!.pushNamedAndRemoveUntil(
              mainPageRoutes[index], (settings) => false);
        },
        leading: NaviPaneLeading(
          small: HoverBox(
            borderRadius: BorderRadius.circular(36),
            child: SizedBox(
              height: 48,
              width: 48,
              child: Avatar(
                url: appdata.user.avatar,
                size: 36,
              ).toCenter(),
            ),
          ).onTapAt((location) {
            showMenu(
                context: context,
                elevation: 3,
                color: context.colorScheme.surface,
                position: RelativeRect.fromLTRB(
                    location.dx, location.dy, location.dx, location.dy),
                items: [
                  PopupMenuItem(
                    height: 42,
                    onTap: () {
                      App.navigatorState!
                          .pushNamed('/user/${appdata.user.username}');
                    },
                    child: Text("Profile".tl),
                  ),
                  PopupMenuItem(
                    height: 42,
                    child: Text("Sign out".tl),
                    onTap: () {
                      appdata.logout();
                      App.rootNavigatorKey!.currentContext!.to('/login');
                    },
                  ),
                ]);
          }),
          large: HoverBox(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Avatar(
                  url: appdata.user.avatar,
                  size: 36,
                ),
                const SizedBox(
                  width: 12,
                ),
                Text(appdata.user.nickname),
              ],
            ).paddingHorizontal(8).paddingVertical(8),
          ).onTapAt((location) {
            showMenu(
                context: context,
                elevation: 3,
                color: context.colorScheme.surface,
                position: RelativeRect.fromLTRB(
                    location.dx, location.dy, location.dx, location.dy),
                items: [
                  PopupMenuItem(
                    height: 42,
                    onTap: () {
                      App.navigatorState!
                          .pushNamed('/user/${appdata.user.username}');
                    },
                    child: Text("Profile".tl),
                  ),
                  PopupMenuItem(
                    height: 42,
                    child: Text("Sign out".tl),
                    onTap: () {
                      appdata.logout();
                      App.rootNavigatorKey!.currentContext!.to('/login');
                    },
                  ),
                ]);
          }),
        ),
        pageBuilder: (index) {
          return Navigator(
            key: App.navigatorKey ??= GlobalKey(),
            observers: [
              observer,
            ],
            initialRoute: mainPageRoutes[index],
            onGenerateRoute: (settings) {
              var builder = routes[settings.name];
              var params = <String, dynamic>{};
              if (builder == null && settings.name != null) {
                var keys = routes.keys;
                for (var key in keys) {
                  params.clear();
                  var routeSegments = key.split('/');
                  var settingsSegments = settings.name!.split('/');
                  if (routeSegments.length == settingsSegments.length) {
                    var match = true;
                    for (var i = 0; i < routeSegments.length; i++) {
                      if (routeSegments[i] == settingsSegments[i]) {
                        continue;
                      }
                      if (routeSegments[i].startsWith(':')) {
                        params[routeSegments[i].substring(1)] =
                            settingsSegments[i];
                      } else {
                        match = false;
                        break;
                      }
                    }
                    if (match) {
                      builder = routes[key];
                      break;
                    }
                  }
                }
              }
              if (settings.arguments is Map<String, dynamic>) {
                params.addAll(settings.arguments as Map<String, dynamic>);
              }
              return AppPageRoute(
                  builder: builder ?? (context) => const UnknownRoutePage(),
                  settings:
                      RouteSettings(name: settings.name, arguments: params),
                  isRootRoute: mainPageRoutes.contains(settings.name));
            },
          );
        },
        observer: observer,
      ),
    ).toCenter();
  }
}
