package com.mindflow.app.mindflow

import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * This file OVERWRITES the MainActivity.kt that `flutter create` generates
 * during every CI build (see codemagic.yaml). It adds just enough native
 * code to support "Open with MindFlow": when Android launches (or
 * re-launches) this activity with an ACTION_VIEW intent carrying a file
 * URI, we read the file's bytes + display name here (this requires
 * Android's ContentResolver, which only native code can call) and hand
 * them to the Dart side over a MethodChannel. Everything else --
 * parsing, importing, navigating to the reader -- stays in Dart, in
 * `IncomingFileChannel` and `app.dart`.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.mindflow.app/open_file"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialFile" -> result.success(readIntentFile(intent))
                else -> result.notImplemented()
            }
        }
    }

    // Called when the app is already running and the user opens another
    // file with MindFlow -- `singleTop` launch mode (set in
    // AndroidManifest.xml) routes here instead of creating a new instance.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val data = readIntentFile(intent)
        if (data != null) {
            methodChannel?.invokeMethod("onFileOpened", data)
        }
    }

    // Flutter's default behavior is to hand the launching intent's data
    // URI (e.g. "content://...") to the Dart side as the *initial route*,
    // which GoRouter then tries to match against a page and fails ("Page
    // Not Found"), since a content:// URI is never one of our routes.
    // Returning null here disables that default deep-link handling --
    // we read the incoming file ourselves (via readIntentFile above) and
    // hand it to Dart through the `getInitialFile`/`onFileOpened` method
    // channel instead, which app.dart uses to import it and navigate to
    // the reader manually, on our own terms.
    override fun getInitialRoute(): String? = null

    private fun readIntentFile(intent: Intent?): HashMap<String, Any>? {
        if (intent == null || intent.action != Intent.ACTION_VIEW) return null
        val uri: Uri = intent.data ?: return null
        return try {
            val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() } ?: return null
            var fileName = "shared_file"
            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (nameIndex >= 0 && cursor.moveToFirst()) {
                    fileName = cursor.getString(nameIndex)
                }
            }
            hashMapOf("bytes" to bytes, "fileName" to fileName, "uri" to uri.toString())
        } catch (e: Exception) {
            null
        }
    }
}
