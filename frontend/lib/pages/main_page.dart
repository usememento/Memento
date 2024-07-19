import 'package:flutter/material.dart';
import 'package:frontend/components/navigation_bar.dart';
import 'package:frontend/pages/page_404.dart';
import 'package:frontend/pages/resource_page.dart';
import 'package:frontend/pages/search_page.dart';
import 'package:frontend/pages/settings_page.dart';
import 'package:frontend/pages/tagged_memos_list_page.dart';
import 'package:frontend/pages/user_page.dart';
import 'package:frontend/utils/translation.dart';

import '../components/button.dart';
import '../components/user.dart';
import '../foundation/app.dart';
import 'explore_page.dart';
import 'following_page.dart';
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
    '/following': (context) => const FollowingPage(),
    '/resources': (context) => const ResourcePage(),
    '/settings': (context) => const SettingsPage(),
    '/search': (context) => const SearchPage(),
    '/memo/:id': (context) => const MemoDetailsPage(),
    '/tag/:tag': (context) => const TaggedMemosListPage(),
    '/user/:username': (context) => const UserInfoPage(),
    '/user/:username/followers': (context) => UserListPage.followers(),
    '/user/:username/following': (context) => UserListPage.following(),
  };

  static const _mainPageRoutes = [
    '/',
    '/explore',
    '/following',
    '/resources',
  ];

  var observer = NaviObserver();

  @override
  void initState() {
    App.observer = observer;
    if(App.initialRoute == '/' && !appdata.isLogin) {
      App.initialRoute = '/explore';
    }
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
            icon: Icons.subscriptions_outlined,
            activeIcon: Icons.subscriptions,
            label: "Following",
            routeName: '/following',
          ),
          PaneItemEntry(
            icon: Icons.my_library_books_outlined,
            activeIcon: Icons.my_library_books,
            label: "Resources",
            routeName: '/resources',
          ),
        ],
        paneActions: [
          if (context.width <= 600)
            PaneActionEntry(
                label: "Search",
                icon: Icons.search,
                onTap: () {
                  App.navigator!.pushNamed('/search');
                }),
          PaneActionEntry(
              routeName: '/settings',
              label: "Settings",
              icon: Icons.settings_outlined,
              onTap: () {
                App.navigator!.pushNamed('/settings');
              }),
        ],
        onPageChange: (index) {
          App.navigator!.pushNamedAndRemoveUntil(
              _mainPageRoutes[index], (settings) => false);
        },
        leading: NaviPaneLeading(
          small: HoverBox(
            borderRadius: BorderRadius.circular(36),
            child: SizedBox(
              height: 48,
              width: 48,
              child: Avatar(
                url: appdata.userOrNull?.avatar ?? "",
                size: 36,
              ).toCenter(),
            ),
          ).onTapAt((location) {
            if (!appdata.isLogin) {
              App.rootNavigatorKey!.currentContext!.to('/login');
              return;
            }
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
                      App.navigator!
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
                  url: appdata.userOrNull?.avatar ?? "",
                  size: 36,
                ),
                const SizedBox(
                  width: 12,
                ),
                Text(appdata.userOrNull?.nickname ?? "Login".tl),
              ],
            ).paddingHorizontal(8).paddingVertical(8),
          ).onTapAt((location) {
            if (!appdata.isLogin) {
              App.rootNavigatorKey!.currentContext!.to('/login');
              return;
            }
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
                      App.navigator!
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
            observers: [
              observer,
            ],
            initialRoute: App.initialRoute,
            reportsRouteUpdateToEngine: true,
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
                  isRootRoute: _mainPageRoutes.contains(settings.name));
            },
          );
        },
        observer: observer,
      ),
    ).toCenter();
  }
}
