package de.doen1el.calibreWebCompanion

import android.content.ActivityNotFoundException
import android.content.ClipData
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "de.doen1el.calibre_web_companion/external_file_opener",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openContentUri" -> {
                    val uri = call.argument<String>("uri")
                    val mimeType = call.argument<String>("mimeType")

                    if (uri.isNullOrBlank()) {
                        result.error("invalid_arguments", "URI is required.", null)
                        return@setMethodCallHandler
                    }

                    try {
                        openContentUri(uri, mimeType)
                        result.success(null)
                    } catch (e: ActivityNotFoundException) {
                        result.error(
                            "activity_not_found",
                            "No app found to open this file.",
                            null,
                        )
                    } catch (e: SecurityException) {
                        result.error(
                            "permission_denied",
                            e.message ?: "Permission denied while opening this file.",
                            null,
                        )
                    } catch (e: Exception) {
                        result.error(
                            "open_failed",
                            e.message ?: "Failed to open this file.",
                            null,
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun openContentUri(uriString: String, mimeType: String?) {
        val uri = Uri.parse(uriString)
        val resolvedMimeType =
            mimeType?.takeIf { it.isNotBlank() }
                ?: contentResolver.getType(uri)?.takeIf { it.isNotBlank() }
                ?: "*/*"

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, resolvedMimeType)
            addCategory(Intent.CATEGORY_DEFAULT)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            clipData = ClipData.newUri(contentResolver, "book", uri)
        }

        startActivity(intent)
    }
}
