import 'package:flutter/material.dart';

import '../../foundation/app.dart';

class Select extends StatefulWidget {
  const Select({
    required this.initialValue,
    this.width = 120,
    required this.onChanged,
    super.key,
    required this.values,
    this.disabledValues = const [],
    this.outline = true,
  });

  ///初始值, 提供values的下标
  final int? initialValue;

  ///可供选取的值
  final List<String> values;

  ///宽度
  final double width;

  ///发生改变时的回调
  final void Function(int) onChanged;
  final List<int> disabledValues;
  final bool outline;

  @override
  State<Select> createState() => _SelectState();
}

class _SelectState extends State<Select> {
  late int? value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    if (value != null && value! < 0) value = null;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        if (widget.values.isEmpty) {
          return;
        }
        final renderBox = context.findRenderObject() as RenderBox;
        var offset = renderBox.localToGlobal(Offset.zero);
        showMenu<int>(
            context: App.rootNavigatorKey!.currentContext!,
            initialValue: value,
            position: RelativeRect.fromLTRB(
                offset.dx, offset.dy, offset.dx, offset.dy),
            constraints: BoxConstraints(
              maxWidth: widget.width,
              minWidth: widget.width,
            ),
            color: context.colorScheme.surface,
            items: [
              for (int i = 0; i < widget.values.length; i++)
                if (!widget.disabledValues.contains(i))
                  PopupMenuItem(
                    height: 42,
                    value: i,
                    onTap: () {
                      setState(() {
                        value = i;
                        widget.onChanged(i);
                      });
                    },
                    child: Text(widget.values[i]),
                  )
            ]);
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        elevation: widget.outline ? 0 : 1,
        child: Container(
          margin: EdgeInsets.zero,
          width: widget.width,
          height: 38,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: widget.outline
                  ? null
                  : Theme.of(context).colorScheme.surfaceContainer,
              border: widget.outline
                  ? Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant)
                  : null),
          child: Row(
            children: [
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child: Text(
                  value == null ? "" : widget.values[value!],
                  overflow: TextOverflow.fade,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const Icon(Icons.arrow_drop_down_sharp)
            ],
          ),
        ),
      ),
    );
  }
}
