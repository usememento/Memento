import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:frontend/foundation/app.dart';

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.url, this.size = 40.0});

  final String url;

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image(
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        image: App.isWeb ? NetworkImage(url) : CachedNetworkImageProvider(url),
      ),
    );
  }
}
