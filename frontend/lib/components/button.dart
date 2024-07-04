import 'package:flutter/material.dart';
import 'package:frontend/foundation/app.dart';

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

enum ButtonType { filled, outlined, text }

class Button extends StatefulWidget {
  const Button(
      {super.key,
      required this.type,
      required this.child,
      this.isLoading = false,
      this.width,
      this.height,
      required this.onPressed});

  const Button.filled(
      {super.key,
      required this.child,
      required this.onPressed,
      this.width,
      this.height,
      this.isLoading = false})
      : type = ButtonType.filled;

  const Button.outlined(
      {super.key,
      required this.child,
      required this.onPressed,
      this.width,
      this.height,
      this.isLoading = false})
      : type = ButtonType.outlined;

  const Button.text(
      {super.key,
      required this.child,
      required this.onPressed,
      this.width,
      this.height,
      this.isLoading = false})
      : type = ButtonType.text;

  final ButtonType type;

  final Widget child;

  final bool isLoading;

  final void Function() onPressed;

  final double? width;

  final double? height;

  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  bool isHover = false;

  bool isLoading = false;

  @override
  void didUpdateWidget(covariant Button oldWidget) {
    if (oldWidget.isLoading != widget.isLoading) {
      setState(() => isLoading = widget.isLoading);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    var width = widget.width;
    if (width != null) {
      width = width - 32;
    }
    var height = widget.height;
    if (height != null) {
      height = height - 16;
    }
    Widget child = DefaultTextStyle(
      style: TextStyle(color: textColor, fontSize: 16),
      child: isLoading
          ? CircularProgressIndicator(
        color: widget.type == ButtonType.filled
            ? context.colorScheme.inversePrimary
            : context.colorScheme.primary,
        strokeWidth: 1.8,
      ).fixWidth(16).fixHeight(16)
          : widget.child,
    );
    if(width != null || height != null){
      child = child.toCenter();
    }
    return MouseRegion(
      onEnter: (_) => setState(() => isHover = true),
      onExit: (_) => setState(() => isHover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isLoading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(8),
            border: widget.type == ButtonType.outlined
                ? Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant)
                : null,
          ),
          child: SizedBox(
            width: width,
            height: height,
            child: child,
          ),
        ),
      ),
    );
  }

  Color get buttonColor {
    if (widget.type == ButtonType.filled) {
      var color = context.colorScheme.primary;
      if (isHover) {
        return color.withOpacity(0.9);
      } else {
        return color;
      }
    }
    if (isHover) {
      return context.colorScheme.surfaceContainerHigh;
    }
    return Colors.transparent;
  }

  Color get textColor {
    return widget.type == ButtonType.filled
        ? context.colorScheme.onPrimary
        : (widget.type == ButtonType.text
            ? context.colorScheme.primary
            : context.colorScheme.onSurface);
  }
}
