import 'dart:convert';
import 'dart:typed_data';

/// Decodes a base64 data URL (e.g. `data:image/png;base64,...`) or a plain
/// base64 string into raw bytes.
Uint8List base64DataUrlToBytes(String dataUrl) {
  final parts = dataUrl.split(',');
  final base64String = parts.length > 1 ? parts[1] : dataUrl;
  return base64Decode(base64String);
}
