import 'dart:typed_data';

import 'package:flutter/services.dart';

/// A file the app was opened/shared with, coming from outside Flutter
/// entirely -- see `android_overrides/MainActivity.kt` for the native
/// side that produces this.
class IncomingFile {
  final Uint8List bytes;
  final String fileName;
  final String? sourceUri;
  const IncomingFile({required this.bytes, required this.fileName, this.sourceUri});
}

/// Dart-side wrapper for the `com.mindflow.app/open_file` MethodChannel.
///
/// Deliberately hand-rolled instead of a third-party "receive sharing
/// intent" package: this app already went through several rounds of
/// dependency-version breakage (see the file_picker/compileSdk history),
/// and this channel only needs ~10 lines of native code, so avoiding a
/// whole extra package here removes one more thing that could later
/// break on an update we don't control.
class IncomingFileChannel {
  IncomingFileChannel._();

  static const _channel = MethodChannel('com.mindflow.app/open_file');

  /// The file MindFlow was launched with (if it was launched via
  /// "Open with", rather than tapped from the home screen). Returns
  /// `null` on any platform where the native side isn't wired up (e.g.
  /// this is a no-op on Windows/Web once those targets are added, unless
  /// they get their own equivalent).
  static Future<IncomingFile?> getInitialFile() async {
    try {
      final result = await _channel.invokeMethod('getInitialFile');
      if (result == null) return null;
      final map = Map<Object?, Object?>.from(result as Map);
      return IncomingFile(
        bytes: map['bytes'] as Uint8List,
        fileName: map['fileName'] as String,
        sourceUri: map['uri'] as String?,
      );
    } on MissingPluginException {
      return null; // Platform has no native handler wired up -- ignore.
    } catch (_) {
      return null;
    }
  }

  /// Fires whenever the app is already open and the user opens another
  /// file with MindFlow (Android's `onNewIntent`).
  static void listenForFileOpened(void Function(IncomingFile file) onFile) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onFileOpened') {
        final map = Map<Object?, Object?>.from(call.arguments as Map);
        onFile(IncomingFile(
          bytes: map['bytes'] as Uint8List,
          fileName: map['fileName'] as String,
          sourceUri: map['uri'] as String?,
        ));
      }
    });
  }
}
