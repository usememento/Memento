import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart' deferred as math;

class MathWidget extends StatefulWidget {
  const MathWidget(
      {super.key,
      required this.content,
      required this.textContent,
      required this.style});

  final String content;

  final String textContent;

  final TextStyle style;

  @override
  State<MathWidget> createState() => _MathWidgetState();
}

class _MathWidgetState extends State<MathWidget> {
  late Future<void> _libraryFuture;

  @override
  void initState() {
    _libraryFuture = math.loadLibrary();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _libraryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return math.Math.tex(
            widget.content,
            mathStyle: math.MathStyle.text,
            textStyle: widget.style,
            textScaleFactor: 1,
            onErrorFallback: (error) {
              return Text(
                widget.textContent,
                style: widget.style.copyWith(color: Colors.red),
              );
            },
          );
        } else {
          return Text(widget.textContent);
        }
      },
    );
  }
}
