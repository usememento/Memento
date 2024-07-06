import 'package:flutter/material.dart';
import 'package:frontend/components/navigation_bar.dart';
import 'package:frontend/pages/page_404.dart';

import '../components/button.dart';
import '../components/user.dart';
import '../foundation/app.dart';
import 'home_page.dart';
import 'memo_details_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static Map<String, Widget Function(BuildContext context)> routes = {
    '/': (context) => const HomePage(),
    '/memo/:id': (context) => const MemoDetailsPage(),
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
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1400),
      child: NaviPane(
        paneItems: [
          PaneItemEntry(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_filled,
            label: "Home",
          ),
          PaneItemEntry(
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore,
            label: "Explore",
          ),
          PaneItemEntry(
            icon: Icons.folder_outlined,
            activeIcon: Icons.folder,
            label: "Archives",
          ),
          PaneItemEntry(
            icon: Icons.my_library_books_outlined,
            activeIcon: Icons.my_library_books,
            label: "Resources",
          ),
          PaneItemEntry(
            icon: Icons.notifications_outlined,
            activeIcon: Icons.notifications,
            label: "Notifications",
          ),
        ],
        paneActions: [
          if (context.width <= 600)
            PaneActionEntry(label: "Search", icon: Icons.search, onTap: () {}),
          PaneActionEntry(
              label: "Settings", icon: Icons.settings_outlined, onTap: () {}),
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
          ).onTap(() {
            // TODO
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
          ).onTap(() {
            // TODO
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
                      if (routeSegments[i] == settingsSegments[i]){
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
              if(settings.arguments is Map<String, dynamic>){
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
