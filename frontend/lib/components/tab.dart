import 'package:flutter/material.dart';
import 'package:frontend/foundation/app.dart';

class IndependentTabBar extends StatefulWidget {
  const IndependentTabBar(
      {super.key,
      required this.tabs,
      required this.onTabChange,
      this.initialIndex = 0});

  final void Function(int i) onTabChange;

  final List<Widget> tabs;

  final int initialIndex;

  @override
  State<IndependentTabBar> createState() => _IndependentTabBarState();
}

class _IndependentTabBarState extends State<IndependentTabBar>
    with SingleTickerProviderStateMixin {
  late TabController controller;

  @override
  void initState() {
    controller = TabController(
        length: widget.tabs.length,
        vsync: this,
        initialIndex: widget.initialIndex);
    controller.addListener(() {
      widget.onTabChange(controller.index);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TabBar(
      tabs: widget.tabs,
      controller: controller,
      isScrollable: true,
      splashBorderRadius: BorderRadius.circular(8),
      tabAlignment: TabAlignment.start,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      labelPadding: const EdgeInsets.symmetric(horizontal: 24),
    ).withSurface();
  }
}
