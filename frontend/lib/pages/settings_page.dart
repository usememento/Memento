import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/button.dart';
import 'package:frontend/components/dialog.dart';
import 'package:frontend/components/flyout.dart';
import 'package:frontend/components/select.dart';
import 'package:frontend/components/states.dart';
import 'package:frontend/components/tab.dart';
import 'package:frontend/components/user.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/main.dart';
import 'package:frontend/network/network.dart';
import 'package:frontend/pages/main_page.dart';
import 'package:frontend/utils/translation.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int index = 0;

  static const List<String> titles = [
    "Account",
    "Preference",
    "Admin",
    "About",
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorScheme.surface,
      child: Column(
        children: [
          Appbar(title: "Settings".tl),
          Expanded(child: buildBody()),
        ],
      ),
    );
  }

  Widget buildBody() {
    if (context.width < 600) {
      return Column(
        children: [
          buildTabBar(),
          Expanded(child: buildContent()),
        ],
      );
    } else {
      return Row(
        children: [
          buildSidebar(),
          Expanded(child: buildContent()),
        ],
      );
    }
  }

  Widget buildTabBar() {
    return IndependentTabBar(
      initialIndex: index,
      tabs: [
        Tab(
          text: "Account".tl,
        ),
        Tab(
          text: "Appearance".tl,
        ),
        Tab(
          text: "Admin".tl,
        ),
        Tab(
          text: "Notifications".tl,
        ),
        Tab(
          text: "About".tl,
        ),
      ],
      onTabChange: (index) {
        setState(() {
          this.index = index;
        });
      },
    );
  }

  Widget buildSidebar() {
    return SizedBox(
      width: 256,
      height: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: List.generate(titles.length, (i) {
            return _SettingsPaneItem(
              title: titles[i].tl,
              onPressed: () {
                setState(() {
                  index = i;
                });
              },
              isActive: index == i,
            );
          }),
        ),
      ),
    );
  }

  Widget buildContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: switch (index) {
        0 => const _AccountSettings(),
        1 => const _PreferenceSettings(),
        2 => const _AdminSettings(),
        3 => const _AboutPage(),
        _ => const Placeholder(),
      },
    );
  }
}

class _SettingsPaneItem extends StatefulWidget {
  const _SettingsPaneItem({
    required this.title,
    required this.onPressed,
    required this.isActive,
  });

  final String title;

  final void Function() onPressed;

  final bool isActive;

  @override
  State<_SettingsPaneItem> createState() => _SettingsPaneItemState();
}

class _SettingsPaneItemState extends State<_SettingsPaneItem> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: MouseRegion(
        onEnter: (_) => setState(() => isHover = true),
        onExit: (_) => setState(() => isHover = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          height: 42,
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.isActive
                ? context.colorScheme.surfaceContainerLow
                : isHover
                    ? context.colorScheme.surfaceContainerLow
                    : null,
            border: Border(
              left: BorderSide(
                color: widget.isActive
                    ? context.colorScheme.primary
                    : context.colorScheme.surface,
                width: 2,
              ),
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(widget.title).paddingLeft(16),
          ),
        ),
      ),
    );
  }
}

class _AccountSettings extends StatefulWidget {
  const _AccountSettings();

  @override
  State<_AccountSettings> createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<_AccountSettings> {
  @override
  Widget build(BuildContext context) {
    if (!appdata.isLogin) {
      return Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("You are not logged in".tl),
          const SizedBox(height: 8),
          Button.filled(
            onPressed: () {
              App.rootNavigatorKey!.currentContext!.to('/login');
            },
            child: Text("Login".tl),
          ),
        ],
      ));
    }

    return Column(
      children: [
        ListTile(
          onTap: () async {
            Uint8List? avatar;
            bool isLoading = false;
            String? avatarFileName;

            await pushDialog(
              context: App.rootNavigatorKey!.currentContext!,
              builder: (context) {
                return StatefulBuilder(builder: (context, setState) {
                  return DialogContent(
                      title: "Change Avatar".tl,
                      body: Center(
                        child: GestureDetector(
                          onTap: () async {
                            const XTypeGroup typeGroup = XTypeGroup(
                              label: 'images',
                              extensions: <String>[
                                'jpg',
                                'png',
                                'jpeg',
                                'gif',
                                'webp'
                              ],
                            );
                            final XFile? file = await openFile(
                                acceptedTypeGroups: <XTypeGroup>[typeGroup]);
                            if (file != null) {
                              avatar = await file.readAsBytes();
                              avatarFileName = file.name;
                              setState(() {});
                            }
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: avatar == null
                                ? Avatar(
                                    url: appdata.user.avatar,
                                    size: 64,
                                  )
                                : Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(64),
                                      image: DecorationImage(
                                        filterQuality: FilterQuality.medium,
                                        image: MemoryImage(avatar!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      actions: [
                        Button.filled(
                            isLoading: isLoading,
                            onPressed: () async {
                              setState(() {
                                isLoading = true;
                              });
                              var context =
                                  App.rootNavigatorKey!.currentContext!;
                              if (avatar != null) {
                                var res = await Network().editProfile(
                                    avatarFileName: avatarFileName,
                                    avatar: avatar!);
                                if (context.mounted) {
                                  if (res.error) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                    context.showMessage(res.message);
                                  } else {
                                    context.pop();
                                    appdata.user = appdata.user
                                        .copyWith(avatar: res.data.avatar);
                                    context.showMessage("Avatar updated".tl);
                                  }
                                }
                              } else {
                                context.showMessage(
                                    "Click avatar to select a new image".tl);
                              }
                            },
                            child: Text("Submit".tl))
                      ]);
                });
              },
            );

            setState(() {});

            if (context.mounted) {
              context.findAncestorStateOfType<MainPageState>()?.setState(() {});
            }
          },
          trailing: Avatar(
            url: appdata.user.avatar,
            size: 36,
          ),
          leading: const Icon(Icons.person),
          title: Text("Avatar".tl),
        ),
        ListTile(
          onTap: () async {
            String name = appdata.user.nickname;
            bool isLoading = false;
            await pushDialog(
              context: App.rootNavigatorKey!.currentContext!,
              builder: (context) {
                return DialogContent(
                  title: "Change Nickname".tl,
                  body: TextField(
                    controller: TextEditingController(text: name),
                    onChanged: (value) {
                      name = value;
                    },
                    decoration: InputDecoration(
                      labelText: "Nickname".tl,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  actions: [
                    Button.filled(
                      isLoading: isLoading,
                      onPressed: () async {
                        setState(() {
                          isLoading = true;
                        });
                        var res = await Network().editProfile(nickname: name);
                        if (context.mounted) {
                          if (res.error) {
                            setState(() {
                              isLoading = false;
                            });
                            context.showMessage(res.message);
                          } else {
                            appdata.user = appdata.user
                                .copyWith(nickname: res.data.nickname);
                            context.pop();
                            context.showMessage("Nickname updated".tl);
                          }
                        }
                      },
                      child: Text("Submit".tl),
                    ),
                  ],
                );
              },
            );

            setState(() {});

            if (context.mounted) {
              context.findAncestorStateOfType<MainPageState>()?.setState(() {});
            }
          },
          trailing: Text(
            appdata.user.nickname,
            style: ts.s14,
          ),
          leading: const Icon(Icons.badge_outlined),
          title: Text("Nickname".tl),
        ),
        ListTile(
          onTap: () {
            String bio = appdata.user.bio;
            bool isLoading = false;
            pushDialog(
              context: App.rootNavigatorKey!.currentContext!,
              builder: (context) {
                return DialogContent(
                  title: "Change Bio".tl,
                  body: TextField(
                    controller: TextEditingController(text: bio),
                    maxLines: null,
                    onChanged: (value) {
                      bio = value;
                    },
                    decoration: InputDecoration(
                      labelText: "Bio".tl,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  actions: [
                    Button.filled(
                      isLoading: isLoading,
                      onPressed: () async {
                        setState(() {
                          isLoading = true;
                        });
                        var res = await Network().editProfile(bio: bio);
                        if (context.mounted) {
                          if (res.error) {
                            setState(() {
                              isLoading = false;
                            });
                            context.showMessage(res.message);
                          } else {
                            appdata.user =
                                appdata.user.copyWith(bio: res.data.bio);
                            context.pop();
                            context.showMessage("Bio updated".tl);
                          }
                        }
                      },
                      child: Text("Submit".tl),
                    ),
                  ],
                );
              },
            );
          },
          leading: const Icon(Icons.insert_drive_file_outlined),
          title: Text("Bio".tl),
        ),
        ListTile(
          onTap: () {
            String password = '';
            String newPassword = '';
            String confirmPassword = '';
            bool isLoading = false;
            pushDialog(
              context: App.rootNavigatorKey!.currentContext!,
              builder: (context) {
                return DialogContent(
                  title: "Change Password".tl,
                  body: Column(
                    children: [
                      TextField(
                        onChanged: (value) {
                          password = value;
                        },
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Current Password".tl,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      TextField(
                        onChanged: (value) {
                          newPassword = value;
                        },
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "New Password".tl,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      TextField(
                        onChanged: (value) {
                          confirmPassword = value;
                        },
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Confirm Password".tl,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    Button.filled(
                      isLoading: isLoading,
                      onPressed: () async {
                        setState(() {
                          isLoading = true;
                        });
                        var res = await Network().changePassword(
                            password: password,
                            newPassword: newPassword,
                            confirmPassword: confirmPassword);
                        if (context.mounted) {
                          if (res.error) {
                            setState(() {
                              isLoading = false;
                            });
                            context.showMessage(res.message);
                          } else {
                            context.pop();
                            context.showMessage("Password updated".tl);
                          }
                        }
                      },
                      child: Text("Submit".tl),
                    ),
                  ],
                );
              },
            );
          },
          leading: const Icon(Icons.password),
          title: Text("Password".tl),
        ),
      ],
    );
  }
}

class _PreferenceSettings extends StatefulWidget {
  const _PreferenceSettings();

  @override
  State<_PreferenceSettings> createState() => __PreferenceSettingsState();
}

class __PreferenceSettingsState extends State<_PreferenceSettings> {
  static const colors = [
    'blue',
    'red',
    'pink',
    'purple',
    'green',
    'orange',
  ];

  static const themeMode = ['system', 'dark', 'light'];

  static const visibility = ['public', 'private'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.color_lens),
          title: Text("Theme".tl),
          trailing: Select(
            initialValue: colors.indexOf(appdata.settings['color'] ?? 'blue'),
            values: colors.map((e) => e.tl).toList(),
            onChanged: (i) async {
              setState(() {
                appdata.settings['color'] = colors[i];
              });
              appdata.saveData();
              await App.init();
              if (context.mounted) {
                context
                    .findAncestorStateOfType<MementoState>()
                    ?.setState(() {});
              }
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: Text("Dark Mode".tl),
          trailing: Select(
            initialValue:
                themeMode.indexOf(appdata.settings['theme_mode'] ?? 'system'),
            values: themeMode.map((e) => e.tl).toList(),
            onChanged: (i) async {
              setState(() {
                appdata.settings['theme_mode'] = themeMode[i];
              });
              appdata.saveData();
              context.findAncestorStateOfType<MementoState>()?.setState(() {});
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.visibility),
          title: Text("Default post visibility".tl),
          trailing: Select(
            initialValue: visibility.indexOf(
                appdata.settings['default_memo_visibility'] ?? 'public'),
            values: visibility.map((e) => e.tl).toList(),
            onChanged: (i) {
              setState(() {
                appdata.settings['default_memo_visibility'] = visibility[i];
              });
              appdata.saveData();
            },
          ),
        ),
      ],
    );
  }
}

class _AdminSettings extends StatefulWidget {
  const _AdminSettings();

  @override
  State<_AdminSettings> createState() => __AdminSettingsState();
}

class __AdminSettingsState
    extends LoadingState<_AdminSettings, Map<String, dynamic>> {
  bool isLoading1 = false;

  @override
  Widget buildContent(BuildContext context, Map<String, dynamic> data) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ListTile(
            leading: const Icon(Icons.app_registration_rounded),
            title: Text("Enable Registration".tl),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading1)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                const SizedBox(width: 8),
                Switch(
                  value: data['enable_register'] == true,
                  onChanged: (v) async {
                    if (isLoading1) return;
                    setState(() {
                      isLoading1 = true;
                    });
                    var res = await Network()
                        .setConfigs({"enable_register": v ? "true" : "false"});
                    if (context.mounted) {
                      if (res.error) {
                        setState(() {
                          isLoading1 = false;
                        });
                        context
                            .showMessage(res.errorMessage ?? "Unknown Error");
                      } else {
                        setState(() {
                          isLoading1 = false;
                          this.data!['enable_register'] = v;
                        });
                      }
                    }
                  },
                )
              ],
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(top: 16)),
        const _UserList(),
      ],
    );
  }

  @override
  Future<Res<Map<String, dynamic>>> loadData() {
    if (!(appdata.userOrNull?.isAdmin ?? false)) {
      return Future.value(const Res.error("Admin permission required"));
    }
    return Network().getConfigs();
  }
}

class _UserList extends StatefulWidget {
  const _UserList();

  @override
  State<_UserList> createState() => _UserListState();
}

class _UserListState extends State<_UserList> {
  int? totalPages;
  int page = 1;
  var data = <int, List<User>>{};
  var loadingStatus = <int, bool>{};

  static const _kBottomBarHeight = 42.0;

  void load(int page) async {
    if (data[page] != null || loadingStatus[page] == true) {
      return;
    }
    loadingStatus[page] = true;
    var res = await Network().getAllUsers(page);
    if (mounted) {
      if (res.error) {
        context.showMessage(res.errorMessage ?? "Unknown Error");
        setState(() {
          loadingStatus[page] = false;
        });
      } else {
        setState(() {
          loadingStatus[page] = false;
          data[page] = res.data;
          totalPages = res.subData;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: context.colorScheme.outlineVariant,
                ),
              ),
            ),
          ),
        ),
        buildUsers(),
        buildBottom().sliverPadding(const EdgeInsets.only(top: 8)),
      ],
    ).sliverPaddingHorizontal(8);
  }

  Widget buildUser(User user) {
    return InkWell(
      onTap: () => editUser(user),
      child: SizedBox(
        height: 42,
        child: Row(
          children: [
            Avatar(
              url: user.avatar,
              size: 32,
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: user.nickname),
                  TextSpan(
                      text: " @${user.username}",
                      style: ts.withColor(context.colorScheme.outline))
                ]),
              ),
            ),
            Text(user.isAdmin ? "Admin" : "User"),
          ],
        ).paddingHorizontal(8),
      ),
    );
  }

  Widget buildUsers() {
    if (data[page] == null) {
      load(page);
      return const SizedBox(
        height: 96,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ).toSliver();
    }
    return SliverList.builder(
      itemCount: data[page]!.length,
      itemBuilder: (context, index) {
        return buildUser(data[page]![index]);
      },
    );
  }

  Widget buildBottom() {
    if (totalPages != null) {
      return Row(
        children: [
          const Spacer(),
          Text(
            "Page".tl,
            style: ts.s16,
          ),
          const SizedBox(
            width: 8,
          ),
          Select(
            initialValue: page - 1,
            values: List.generate(totalPages!, (i) => (i + 1).toString()),
            onChanged: (i) => setState(() {
              page = i + 1;
            }),
          )
        ],
      ).fixHeight(_kBottomBarHeight).toSliver();
    } else {
      return const SliverPadding(
          padding: EdgeInsets.only(top: _kBottomBarHeight));
    }
  }

  void editUser(User user) {
    pushDialog(
        context: App.rootNavigatorKey!.currentContext!,
        builder: (_) =>
            _EditUserDialog(user: user, state: this));
  }
}

class _EditUserDialog extends StatefulWidget {
  const _EditUserDialog({required this.user, required this.state});

  final User user;

  final _UserListState state;

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  User get user => widget.user;

  bool l1 = false;
  bool l2 = false;

  var controller = FlyoutController();

  @override
  Widget build(BuildContext context) {
    return DialogContent(
      title: user.nickname,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 42,
            child: Row(
              children: [
                Text("Register Time".tl),
                const Spacer(),
                Text(user.createdAt
                    .toIso8601String()
                    .substring(0, 19)
                    .replaceFirst('T', ' ')),
              ],
            ),
          ),
          SizedBox(
            height: 42,
            child: Row(
              children: [
                Text("Total Posts".tl),
                const Spacer(),
                Text(user.totalPosts.toString()),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (!user.isAdmin)
          Button.outlined(
              isLoading: l1,
              onPressed: setPermission,
              child: Text("Set As Admin".tl)),
        if (user.isAdmin)
          Button.outlined(
              isLoading: l1,
              onPressed: setPermission,
              child: Text("Set As User".tl)),
        const SizedBox(
          width: 8,
        ),
        Flyout(
          controller: controller,
          flyoutBuilder: (context) => FlyoutContent(
            title: "Are you sure to delete this user?".tl,
            actions: [
              Button.outlined(
                onPressed: () {
                  context.pop();
                },
                child: Text("Cancel".tl),
              ),
              Button.filled(
                onPressed: () {
                  context.pop();
                  deleteUser();
                },
                color: Colors.red,
                child: Text("Delete".tl),
              ),
            ],
          ),
          child: Button.filled(
            isLoading: l2,
            onPressed: () {
              controller.show();
            },
            color: Colors.red,
            child: Text("Delete".tl),
          ),
        )
      ],
    );
  }

  void setPermission() async {
    setState(() {
      l1 = true;
    });
    var res = await Network().setPermission(user.username, !user.isAdmin);
    if (mounted) {
      if (res.error) {
        setState(() {
          l1 = false;
        });
        context.showMessage(res.errorMessage ?? "Unknown Error");
      } else {
        setState(() {
          l1 = false;
        });
        user.isAdmin = !user.isAdmin;
        if (widget.state.mounted) {
          widget.state.setState(() {});
        }
        context.pop();
      }
    }
  }

  void deleteUser() async {
    setState(() {
      l2 = true;
    });
    var res = await Network().deleteUser(user.username);
    if (mounted) {
      if (res.error) {
        setState(() {
          l2 = false;
        });
        context.showMessage(res.errorMessage ?? "Unknown Error");
      } else {
        setState(() {
          l2 = false;
        });
        if (widget.state.mounted) {
          widget.state.data
              .clear();
          widget.state.setState(() {});
        }
        context.pop();
      }
    }
  }
}

class _AboutPage extends StatelessWidget {
  const _AboutPage();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Memento", style: ts.s24,).paddingLeft(16).paddingBottom(8),
        ListTile(
          title: const Text("Version"),
          subtitle: Text(App.version),
        ),
        ListTile(
          title: const Text("Github"),
          subtitle: const Text("https://github.com/useMemento/Memento"),
          onTap: () {
            launchUrlString("https://github.com/useMemento/Memento");
          },
        ),
      ],
    ).fixWidth(double.infinity);
  }
}
