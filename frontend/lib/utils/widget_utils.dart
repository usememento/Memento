import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/components/overlay.dart';
import 'package:frontend/foundation/app.dart';

extension WidgetExtension on Widget {
  Widget padding(EdgeInsetsGeometry padding) {
    return Padding(padding: padding, child: this);
  }

  Widget paddingLeft(double padding) {
    return Padding(padding: EdgeInsets.only(left: padding), child: this);
  }

  Widget paddingRight(double padding) {
    return Padding(padding: EdgeInsets.only(right: padding), child: this);
  }

  Widget paddingTop(double padding) {
    return Padding(padding: EdgeInsets.only(top: padding), child: this);
  }

  Widget paddingBottom(double padding) {
    return Padding(padding: EdgeInsets.only(bottom: padding), child: this);
  }

  Widget paddingVertical(double padding) {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: padding), child: this);
  }

  Widget paddingHorizontal(double padding) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: padding), child: this);
  }

  Widget paddingAll(double padding) {
    return Padding(padding: EdgeInsets.all(padding), child: this);
  }

  Widget toCenter() {
    return Center(child: this);
  }

  Widget toAlign(AlignmentGeometry alignment) {
    return Align(alignment: alignment, child: this);
  }

  Widget sliverPadding(EdgeInsetsGeometry padding) {
    return SliverPadding(padding: padding, sliver: this);
  }

  Widget sliverPaddingAll(double padding) {
    return SliverPadding(padding: EdgeInsets.all(padding), sliver: this);
  }

  Widget sliverPaddingVertical(double padding) {
    return SliverPadding(
        padding: EdgeInsets.symmetric(vertical: padding), sliver: this);
  }

  Widget sliverPaddingHorizontal(double padding) {
    return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: padding), sliver: this);
  }

  Widget fixWidth(double width) {
    return SizedBox(width: width, child: this);
  }

  Widget fixHeight(double height) {
    return SizedBox(height: height, child: this);
  }

  Widget onTap(Function() onTap) {
    return GestureDetector(onTap: onTap, child: this);
  }

  Widget onTapAt(Function(Offset) onTap) {
    return GestureDetector(
        onTapUp: (details) {
          onTap(details.globalPosition);
        },
        child: this);
  }

  Widget expanded() {
    return SizedBox(
        width: double.infinity, height: double.infinity, child: this);
  }

  Widget withSurface([Color? color]) {
    return _Surface(this, color);
  }

  Widget toSliver() {
    return SliverToBoxAdapter(child: this);
  }
}

class _Surface extends StatelessWidget {
  const _Surface(this.child, [this.color]);

  final Widget child;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? context.colorScheme.surface,
      child: child,
    );
  }
}

extension ContextExt on BuildContext {
  void pop<T>([T? result]) {
    Navigator.of(this).pop(result);
  }

  Future<T?> to<T>(String path, [Map<String, dynamic> params = const {}]) {
    return Navigator.of(this).pushNamed(path, arguments: params);
  }

  Future<T?> toWidget<T>(WidgetBuilder builder,
      [Map<String, dynamic> params = const {}]) {
    return Navigator.of(this).push(AppPageRoute(builder: builder));
  }

  Future<T?> toAndRemoveAll<T>(String path,
      [Map<String, String> params = const {}]) {
    return Navigator.of(this)
        .pushNamedAndRemoveUntil(path, (settings) => false, arguments: params);
  }

  Size get size => MediaQuery.of(this).size;

  double get width => MediaQuery.of(this).size.width;

  double get height => MediaQuery.of(this).size.height;

  EdgeInsets get padding => MediaQuery.of(this).padding;

  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  bool get isDarkMode {
    return Theme.of(this).brightness == Brightness.dark;
  }

  void showMessage(String message, {Widget? trailing, Widget? leading}) {
    OverlayWidget.of(this)
        .showMessage(message, trailing: trailing, leading: leading);
  }

  void showError(String message) {
    OverlayWidget.of(this).showError(message);
  }

  dynamic param(String key) {
    return (ModalRoute.of(this)!.settings.arguments! as Map)[key];
  }
}

class MenuEntry {
  MenuEntry(this.title, this.onTap);

  final String title;

  final Function() onTap;
}

Future<void> showPopMenu(Offset location, List<MenuEntry> items) {
  return showMenu(
      elevation: 3,
      color: App.rootNavigatorKey!.currentContext!.colorScheme.surface,
      context: App.rootNavigatorKey!.currentContext!,
      position: RelativeRect.fromLTRB(location.dx, location.dy, location.dx, location.dy),
      items: items
          .map((e) => PopupMenuItem(
                onTap: e.onTap,
                height: 42,
                child: Text(e.title),
              ))
          .toList());
}

/// create default text style
TextStyle get ts => const TextStyle();

extension StyledText on TextStyle {
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);

  TextStyle get italic => copyWith(fontStyle: FontStyle.italic);

  TextStyle get underline => copyWith(decoration: TextDecoration.underline);

  TextStyle get lineThrough => copyWith(decoration: TextDecoration.lineThrough);

  TextStyle get overline => copyWith(decoration: TextDecoration.overline);

  TextStyle get s8 => copyWith(fontSize: 8);

  TextStyle get s10 => copyWith(fontSize: 10);

  TextStyle get s12 => copyWith(fontSize: 12);

  TextStyle get s14 => copyWith(fontSize: 14);

  TextStyle get s16 => copyWith(fontSize: 16);

  TextStyle get s18 => copyWith(fontSize: 18);

  TextStyle get s20 => copyWith(fontSize: 20);

  TextStyle get s24 => copyWith(fontSize: 24);

  TextStyle get s28 => copyWith(fontSize: 28);

  TextStyle get s32 => copyWith(fontSize: 32);

  TextStyle get s36 => copyWith(fontSize: 36);

  TextStyle get s40 => copyWith(fontSize: 40);
}