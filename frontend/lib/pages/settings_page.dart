import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/button.dart';
import 'package:frontend/components/dialog.dart';
import 'package:frontend/components/tab.dart';
import 'package:frontend/components/user.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/network/network.dart';
import 'package:frontend/pages/main_page.dart';
import 'package:frontend/utils/translation.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int index = 0;

  static const List<String> titles = [
    "Account",
    "Appearance",
    "Notifications",
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
