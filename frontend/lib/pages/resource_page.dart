import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/components/appbar.dart';
import 'package:frontend/components/button.dart';
import 'package:frontend/components/dialog.dart';
import 'package:frontend/components/flyout.dart';
import 'package:frontend/components/states.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/network/network.dart';
import 'package:frontend/utils/ext.dart';
import 'package:frontend/utils/translation.dart';
import 'package:frontend/utils/upload.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ResourcePage extends StatefulWidget {
  const ResourcePage({super.key});

  @override
  State<ResourcePage> createState() => _ResourcePageState();
}

class _ResourcePageState extends State<ResourcePage> {
  final _controller = _FileListController();

  @override
  Widget build(BuildContext context) {
    if(!appdata.isLogin) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Login Required".tl, style: ts.bold.s16,),
            const SizedBox(height: 12,),
            Button.filled(child: Text("Login".tl), onPressed: () {
              App.rootNavigatorKey!.currentContext!.to('/login');
            })
          ],
        ),
      );
    }
    return Material(
      color: context.colorScheme.surface,
      child: CustomScrollView(
        slivers: [
          SliverAppbar(
            title: Text("Resources".tl),
            actions: [buildUploadButton()],
          ).sliverPaddingHorizontal(8),
          _FileList(
            controller: _controller,
          )
        ],
      ),
    );
  }

  Widget buildUploadButton() {
    return Button.outlined(
        child: Text("Upload".tl),
        onPressed: () {
          uploadFile(
              null,
              const XTypeGroup(
                label: "file",
              )).then((v) {
            if (mounted && v != null) {
              _controller.uploadNewFile(v);
            }
          });
        });
  }
}

class _FileWidget extends StatelessWidget {
  const _FileWidget({required this.file, required this.deletedCallback});

  final ServerFile file;

  final void Function() deletedCallback;

  Widget buildIcon(BuildContext context) {
    var ext = file.name.split('.').last;
    const image = Icon(Icons.image);
    const doc = Icon(Icons.article);
    const compress = Icon(Icons.compress);
    var icon = switch (ext) {
      'jpg' => image,
      'jpge' => image,
      'png' => image,
      'webp' => image,
      'gif' => image,
      'txt' => doc,
      'md' => doc,
      'doc' => doc,
      'docx' => doc,
      'pdf' => doc,
      'zip' => compress,
      '7z' => compress,
      'rar' => compress,
      'gz' => compress,
      _ => const Icon(Icons.insert_drive_file_outlined)
    };
    return IconTheme.merge(
        data: IconThemeData(size: 24, color: context.colorScheme.primary),
        child: icon);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: showDialog,
      child: SizedBox(
        height: 36,
        width: double.infinity,
        child: Row(
          children: [
            buildIcon(context),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Text(file.name),
            ),
            const SizedBox(
              width: 12,
            ),
            Text(file.time.toCompareString()),
          ],
        ).paddingHorizontal(8),
      ),
    ).paddingHorizontal(16);
  }

  void showDialog() async {
    var domain = App.isWeb ? Uri.base.toString() : appdata.settings['domain'];
    var link = "$domain/api/file/download/${file.id}";
    bool isDeleted = false;
    await pushDialog(
        context: App.rootNavigatorKey!.currentContext!,
        builder: (context) {
          var controller = FlyoutController();
          return DialogContent(
            title: file.name,
            body: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: context.colorScheme.outlineVariant)),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          link,
                          maxLines: null,
                        ),
                      ),
                      Button.icon(
                          size: 18,
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: link));
                            context.showMessage("Copied".tl);
                          })
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Flyout(
                  controller: controller,
                  flyoutBuilder: (context) {
                    bool isLoading = false;
                    return FlyoutContent(
                        title: "Are you sure you want to delete this file?".tl,
                        actions: [
                          StatefulBuilder(builder: (context, setState) {
                            return Button.outlined(
                                isLoading: isLoading,
                                color: Colors.red,
                                onPressed: () async {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  var res = await Network()
                                      .deleteFile(file.id.toString());
                                  if (context.mounted) {
                                    if (res.error) {
                                      setState(() {
                                        isLoading = false;
                                      });
                                      context.showMessage(res.errorMessage!);
                                    } else {
                                      var navigator =
                                          App.rootNavigatorKey!.currentState!;
                                      isDeleted = true;
                                      navigator.pop();
                                      navigator.pop();
                                      App.rootNavigatorKey!.currentContext!
                                          .showMessage("Deleted".tl);
                                    }
                                  }
                                },
                                child: Text("Confirm".tl));
                          }),
                          const SizedBox(
                            width: 8,
                          ),
                          Button.filled(
                              child: Text("Cancel".tl),
                              onPressed: () {
                                context.pop();
                              })
                        ]);
                  },
                  child: Button.text(
                      color: Colors.red,
                      onPressed: () {
                        controller.show();
                      },
                      child: Text("Delete".tl))),
              const SizedBox(
                width: 8,
              ),
              Button.text(
                  child: Text("Download".tl),
                  onPressed: () {
                    launchUrlString(link);
                  }),
            ],
          );
        });

    if (isDeleted) {
      deletedCallback();
    }
  }
}

class _FileListController {
  __FileListState? state;

  void uploadNewFile(ServerFile file) {
    state?.uploadNewFile(file);
  }
}

class _FileList extends StatefulWidget {
  const _FileList({required this.controller});

  final _FileListController controller;

  @override
  State<_FileList> createState() => __FileListState();
}

class __FileListState extends MultiPageLoadingState<_FileList, ServerFile> {
  @override
  void initState() {
    widget.controller.state = this;
    super.initState();
  }

  void uploadNewFile(ServerFile file) {
    if (data != null) {
      setState(() {
        data!.insert(0, file);
      });
    }
  }

  @override
  Widget buildLoading(BuildContext context) {
    return SliverToBoxAdapter(
      child: Center(
        child: const CircularProgressIndicator(
          strokeWidth: 2,
        ).fixWidth(18).fixHeight(18),
      ).fixHeight(64),
    );
  }

  @override
  Widget buildError(BuildContext context, String error) {
    return SliverToBoxAdapter(
      child: super.buildError(context, error),
    );
  }

  Iterable<Widget> generateWidgets(List<ServerFile> files) sync* {
    var time = "";
    for (var file in files) {
      var fileTime = "${file.time.year}•${file.time.month}";
      if (time != fileTime) {
        time = fileTime;
        yield Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            time,
            style: ts.bold.s18,
          ),
        );
      }
      yield _FileWidget(
        file: file,
        deletedCallback: () {
          setState(() {
            files.remove(file);
          });
        },
      );
    }
  }

  @override
  Widget buildContent(BuildContext context, List<ServerFile> data) {
    var widgets = generateWidgets(data).toList();
    return SliverList(
        delegate: SliverChildBuilderDelegate(
      (context, index) {
        if(index == widgets.length - 1) {
          nextPage();
        }
        return widgets[index];
      },
      childCount: widgets.length,
    ));
  }

  @override
  Future<Res<List<ServerFile>>> loadData(int page) {
    return Network().getFileList(page);
  }
}
