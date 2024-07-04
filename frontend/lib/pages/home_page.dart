import 'package:flutter/material.dart';
import 'package:frontend/components/button.dart';
import 'package:frontend/foundation/app.dart';
import 'package:frontend/utils/translation.dart';

import '../components/heat_map.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constrains) {
      return Row(
        children: [
          const Expanded(
            child: CustomScrollView(
              slivers: [
                WritingArea(),
              ],
            ),
          ),
          if(context.width >= 600)
            Container(
              width: (constrains.maxWidth - 324).clamp(0, 286),
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: context.colorScheme.outlineVariant,
                    width: 0.4,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16,),
                    Container(
                      height: 42,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: "Search",
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (s) {
                          context.to("/search", {
                            "keyword": s,
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16,),
                    HeatMap(data: getTestData())
                  ],
                ),
              ),
            )
        ],
      );
    });
  }
}

class WritingArea extends StatefulWidget {
  const WritingArea({super.key});

  @override
  State<WritingArea> createState() => _WritingAreaState();
}

class _WritingAreaState extends State<WritingArea> {
  var content = '';

  bool isPublic = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.outlineVariant,
            width: 0.4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: "Write what you think...",
              border: InputBorder.none,
            ),
            onChanged: (value) {
              setState(() {
                content = value;
              });
            },
            maxLines: null,
          ).fixWidth(double.infinity),
          Container(
            height: 0.4,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 12),
            color: context.colorScheme.outlineVariant,
          ),
          Row(
            children: [
              Tooltip(
                message: "Click to change visibility".tl,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      isPublic = !isPublic;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: [
                      if (isPublic)
                        Icon(
                          Icons.public,
                          size: 18,
                          color: context.colorScheme.primary,
                        ),
                      if (!isPublic)
                        Icon(
                          Icons.lock,
                          size: 18,
                          color: context.colorScheme.primary,
                        ),
                      const Spacer(),
                      Text(
                        isPublic ? "Public".tl : "Private".tl,
                        style: TextStyle(color: context.colorScheme.primary),
                      ),
                      const Spacer(),
                    ],
                  ).fixWidth(72).paddingHorizontal(8).paddingVertical(4),
                ),
              ),
              Button.icon(
                  icon: const Icon(Icons.image_outlined),
                  size: 18,
                  tooltip: "Upload image".tl,
                  onPressed: () {}),
              Button.icon(
                  icon: const Icon(Icons.fullscreen),
                  size: 18,
                  tooltip: "Full screen".tl,
                  onPressed: () {}),
              Button.icon(
                  icon: const Icon(Icons.info_outline),
                  size: 18,
                  tooltip: "Content syntax".tl,
                  onPressed: () {}),
              const Spacer(),
              Button.filled(
                onPressed: post,
                child: Text("Post".tl),
              )
            ],
          )
        ],
      ),
    ).toSliver();
  }

  void post() {
    if (content.isEmpty) {
      return;
    }
    // Post content to the server
  }
}

