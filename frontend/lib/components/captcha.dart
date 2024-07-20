import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/utils/translation.dart';

import '../network/network.dart';

class CaptchaWidget extends StatefulWidget {
  const CaptchaWidget({super.key, required this.onCaptchaCompleted});

  final void Function(String) onCaptchaCompleted;

  @override
  State<CaptchaWidget> createState() => _CaptchaWidgetState();
}

class _CaptchaWidgetState extends State<CaptchaWidget> {
  bool _isCaptchaValid = false;

  bool _isCaptchaLoading = false;

  void startCaptcha() async {
    if(_isCaptchaLoading) return;
    if(_isCaptchaValid) {
      setState(() {
        _isCaptchaValid = false;
      });
    }
    setState(() {
      _isCaptchaLoading = true;
    });
    var captcha = await Network().getCaptcha();
    if(!mounted) return;
    if(captcha.error) {
      context.showMessage(captcha.message);
      setState(() {
        _isCaptchaLoading = false;
      });
    }
    var backgroundImage = base64Decode(captcha.data.backgroundImage);
    var sliderImage = base64Decode(captcha.data.sliderImage);
    String? answer;

    await Navigator.of(context).push(DialogRoute(
      context: context,
      builder: (context) {
        return SliderCaptcha(
          backgroundImage: backgroundImage,
          sliderImage: sliderImage,
          onCaptchaCompleted: (value) {
            answer = value.toString();
          },
        );
      },
    ));

    if(answer == null) {
      setState(() {
        _isCaptchaLoading = false;
      });
      return;
    }

    var res = await Network().verifyCaptcha(captcha.data.identifier, answer!);
    if(!mounted) return;
    if(res.error) {
      context.showMessage(res.message);
      setState(() {
        _isCaptchaLoading = false;
      });
    } else {
      setState(() {
        _isCaptchaValid = true;
        _isCaptchaLoading = false;
      });
      widget.onCaptchaCompleted(res.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.colorScheme.outline),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
          ),
          if(!_isCaptchaLoading)
            InkWell(
              onTap: startCaptcha,
              child: _isCaptchaValid
                  ? Icon(
                      Icons.check_box,
                      color: context.colorScheme.primary,
                    )
                  : Icon(
                      Icons.check_box_outline_blank,
                      color: context.colorScheme.primary,
                    ),
            )
          else
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2,),
            ),
          const SizedBox(width: 12),
          Text(
            "I'm human",
            style: ts.s14,
          ),
        ],
      ),
    );
  }
}

class SliderCaptcha extends StatefulWidget {
  const SliderCaptcha(
      {super.key,
      required this.backgroundImage,
      required this.sliderImage,
      required this.onCaptchaCompleted});

  final Uint8List backgroundImage;

  final Uint8List sliderImage;

  final void Function(int) onCaptchaCompleted;

  @override
  State<SliderCaptcha> createState() => _SliderCaptchaState();
}

class _SliderCaptchaState extends State<SliderCaptcha>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late HorizontalDragGestureRecognizer _gestureRecognizer;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: 256 - 36,
      value: 0,
      duration: const Duration(milliseconds: 500),
    );
    _gestureRecognizer = HorizontalDragGestureRecognizer()
      ..onStart = handleDragStart
      ..onUpdate = handleDragUpdate
      ..onEnd = handleDragEnd;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _gestureRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Material(
            color: Colors.transparent,
            child: Container(
              width: 300,
              height: 270,
              padding: const EdgeInsets.all(8)
                  + const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 26,
                    child: Center(
                      child: Text("Move the slider to correct position".tl,
                          style: ts.s16),
                    ),
                  ),
                  const SizedBox(height: 8,),
                  SizedBox(
                    height: 160,
                    width: 256,
                    child: Stack(
                      children: [
                        Positioned.fill(child: Image.memory(widget.backgroundImage)),
                        Positioned(
                          top: 62,
                          left: _controller.value,
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: Image.memory(widget.sliderImage),
                          ),
                        ),
                      ],
                    ),
                  ).paddingHorizontal(14),
                  const SizedBox(
                    height: 4,
                  ),
                  Container(
                    height: 28,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: _controller.value,
                          child: Listener(
                            onPointerDown: (event) {
                              _gestureRecognizer.addPointer(event);
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: context.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ).paddingVertical(6).paddingHorizontal(14)
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void handleDragStart(DragStartDetails details) {
    // ignore
  }

  void handleDragUpdate(DragUpdateDetails details) {
    var offset = details.primaryDelta!;
    _controller.value += offset;
  }

  void handleDragEnd(DragEndDetails details) {
    widget.onCaptchaCompleted((_controller.value / (256 - 36) * 100).round());
    context.pop();
  }
}
