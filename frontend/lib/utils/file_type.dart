import 'dart:typed_data';

enum FileType {
  jpg([0xFF, 0xD8, 0xFF, 0xE0]),
  png([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
  gif([0x47, 0x49, 0x46, 0x38]),
  webp([0x52, 0x49, 0x46, 0x46]),
  unknown([]);

  const FileType(this.headerBytes);
  final List<int> headerBytes;
}

FileType detectFileType(Uint8List data) {
  for (var type in FileType.values) {
    if (data.length >= type.headerBytes.length &&
        type.headerBytes.every((e) => e == data[type.headerBytes.indexOf(e)])) {
      return type;
    }
  }
  return FileType.unknown;
}