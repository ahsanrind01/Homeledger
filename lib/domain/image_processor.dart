import 'dart:isolate';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Pure function to decode, fix orientation, resize, and encode image bytes.
///
/// Rules:
/// - Decode raw image bytes.
/// - Fix EXIF orientation via [img.bakeOrientation].
/// - Resize so the longest side is at most [maxDimension] (default 1600 px).
/// - Do NOT enlarge images where both dimensions are <= [maxDimension].
/// - Encode as JPEG at [quality]% (default 80%).
Uint8List processImageBytes({
  required Uint8List rawBytes,
  int maxDimension = 1600,
  int quality = 80,
}) {
  final image = img.decodeImage(rawBytes);
  if (image == null) {
    throw const FormatException('Unable to decode image bytes.');
  }

  // 1. Fix orientation according to EXIF tags
  final oriented = img.bakeOrientation(image);

  // 2. Resize only if the longest side exceeds maxDimension
  final width = oriented.width;
  final height = oriented.height;
  final longestSide = width > height ? width : height;

  final img.Image resized;
  if (longestSide > maxDimension) {
    if (width >= height) {
      resized = img.copyResize(oriented, width: maxDimension);
    } else {
      resized = img.copyResize(oriented, height: maxDimension);
    }
  } else {
    // Keep small image at original dimensions (never enlarge)
    resized = oriented;
  }

  // 3. Encode to JPEG at specified quality
  return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
}

/// Runs [processImageBytes] on a background isolate using [Isolate.run]
/// so the UI thread never stutters or drops frames during heavy image decoding/encoding.
Future<Uint8List> processImageInBackground(
  Uint8List rawBytes, {
  int maxDimension = 1600,
  int quality = 80,
}) {
  return Isolate.run(
    () => processImageBytes(
      rawBytes: rawBytes,
      maxDimension: maxDimension,
      quality: quality,
    ),
  );
}

