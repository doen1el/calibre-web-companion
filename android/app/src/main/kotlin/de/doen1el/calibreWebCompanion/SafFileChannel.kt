package de.doen1el.calibreWebCompanion

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.webkit.MimeTypeMap
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

// docman rewrites spaces/brackets to '_' and cuts names at the first dot, which
// breaks KOReader's filename-based sync (#223), so downloads are copied here.
class SafFileChannel(private val context: Context, messenger: BinaryMessenger) {
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    init {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "copyFileToDirectory" -> {
                    val source = call.argument<String>("source")
                    val directory = call.argument<String>("directory")
                    val name = call.argument<String>("name")
                    if (source == null || directory == null || name.isNullOrEmpty()) {
                        result.error("invalid_args", "source, directory and name are required", null)
                        return@setMethodCallHandler
                    }
                    executor.execute {
                        try {
                            val uri = copyFileToDirectory(File(source), Uri.parse(directory), name)
                            mainHandler.post { result.success(uri.toString()) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("copy_failed", e.message, null) }
                        }
                    }
                }
                "renameDocument" -> {
                    val uri = call.argument<String>("uri")
                    val name = call.argument<String>("name")
                    if (uri == null || name.isNullOrEmpty()) {
                        result.error("invalid_args", "uri and name are required", null)
                        return@setMethodCallHandler
                    }
                    executor.execute {
                        try {
                            val renamed = DocumentsContract.renameDocument(
                                context.contentResolver,
                                Uri.parse(uri),
                                name,
                            )
                            mainHandler.post { result.success(renamed?.toString()) }
                        } catch (e: Exception) {
                            mainHandler.post { result.error("rename_failed", e.message, null) }
                        }
                    }
                }
                "openDocument" -> {
                    val uri = call.argument<String>("uri")
                    val mimeType = call.argument<String>("mimeType")
                    if (uri == null) {
                        result.error("invalid_args", "uri is required", null)
                        return@setMethodCallHandler
                    }
                    result.success(openDocument(Uri.parse(uri), mimeType))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun copyFileToDirectory(source: File, directory: Uri, name: String): Uri {
        val resolver = context.contentResolver
        val parent = if (DocumentsContract.isDocumentUri(context, directory)) {
            directory
        } else {
            DocumentsContract.buildDocumentUriUsingTree(
                directory,
                DocumentsContract.getTreeDocumentId(directory),
            )
        }

        val extension = name.substringAfterLast('.', "").lowercase()
        val mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)
            ?: "application/octet-stream"

        val target = DocumentsContract.createDocument(resolver, parent, mimeType, name)
            ?: throw IllegalStateException("Could not create \"$name\"")

        try {
            val output = resolver.openOutputStream(target, "w")
                ?: throw IllegalStateException("Could not open \"$name\" for writing")
            output.use { out -> source.inputStream().use { it.copyTo(out) } }
        } catch (e: Exception) {
            runCatching { DocumentsContract.deleteDocument(resolver, target) }
            throw e
        }
        return target
    }

    // Hands the SAF document itself to the reader. A copy from the app cache
    // makes KOReader import it outside the sync folder (#225).
    private fun openDocument(uri: Uri, mimeType: String?): Boolean {
        val type = mimeType
            ?: context.contentResolver.getType(uri)
            ?: "application/octet-stream"
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, type)
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_ACTIVITY_NEW_TASK,
            )
        }
        return try {
            context.startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        } catch (e: SecurityException) {
            false
        }
    }

    companion object {
        const val CHANNEL = "de.doen1el.calibreWebCompanion/saf"
    }
}
