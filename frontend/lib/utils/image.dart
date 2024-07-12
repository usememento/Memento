import 'dart:typed_data';

import 'package:image/image.dart' as image;

(Uint8List data, String ext) resizeImage(Uint8List imageBytes, int width) {
  final img = image.decodeImage(imageBytes);
  if (img == null) {
    throw Exception('Invalid image');
  }
  final resizedImage = image.copyResize(img,
      width: width,
      maintainAspect: true,
      interpolation: image.Interpolation.linear);
  Uint8List res;
  String ext;
  if (resizedImage.frames.length > 1) {
    res = image.encodeGif(resizedImage);
    ext = 'gif';
  } else {
    res = image.encodeJpg(resizedImage);
    ext = 'jpg';
  }
  return (res, ext);
}
