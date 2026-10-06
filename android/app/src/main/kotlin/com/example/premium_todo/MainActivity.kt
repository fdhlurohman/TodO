package com.example.premium_todo

import android.app.Activity
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val soundPickerRequestCode = 5107
    private var soundPickerResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "my.id.fads.todo/notification_sound_picker",
        ).setMethodCallHandler { call, result ->
            if (call.method != "pickAudio") {
                if (call.method == "canReadAudioUri") {
                    val uriValue = call.argument<String>("uri")
                    result.success(uriValue != null && canReadAudioUri(Uri.parse(uriValue)))
                } else {
                    result.notImplemented()
                }
                return@setMethodCallHandler
            }
            if (soundPickerResult != null) {
                result.error("picker_busy", "Pemilih file sedang dibuka.", null)
                return@setMethodCallHandler
            }

            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "audio/*"
                addFlags(
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
                )
            }
            soundPickerResult = result
            try {
                startActivityForResult(intent, soundPickerRequestCode)
            } catch (error: Exception) {
                soundPickerResult = null
                result.error("picker_unavailable", error.message, null)
            }
        }
    }

    @Deprecated("Deprecated in Android, retained for FlutterActivity result handling.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != soundPickerRequestCode) return

        val result = soundPickerResult ?: return
        soundPickerResult = null
        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return
        }

        val uri = data?.data
        if (uri == null) {
            result.error("missing_uri", "File suara tidak ditemukan.", null)
            return
        }

        try {
            val grantedFlags = data.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION
            if (grantedFlags == 0) {
                result.error(
                    "sound_access_denied",
                    "Android tidak memberikan izin membaca file suara.",
                    null,
                )
                return
            }
            contentResolver.takePersistableUriPermission(uri, grantedFlags)
            if (!canReadAudioUri(uri)) {
                result.error(
                    "sound_unreadable",
                    "File tidak dapat dibaca sebagai suara notifikasi.",
                    null,
                )
                return
            }
            result.success(
                mapOf(
                    "uri" to uri.toString(),
                    "name" to displayName(uri),
                ),
            )
        } catch (error: Exception) {
            result.error("sound_access_failed", error.message, null)
        }
    }

    private fun canReadAudioUri(uri: Uri): Boolean {
        if (uri.scheme != "content") return false
        return try {
            contentResolver.openFileDescriptor(uri, "r")?.use { true } ?: false
        } catch (_: Exception) {
            false
        }
    }

    private fun displayName(uri: Uri): String {
        var cursor: Cursor? = null
        return try {
            cursor = contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME),
                null,
                null,
                null,
            )
            if (cursor != null && cursor.moveToFirst()) {
                val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (nameIndex >= 0) cursor.getString(nameIndex) else null
            } else {
                null
            } ?: uri.lastPathSegment ?: "Suara pilihan"
        } finally {
            cursor?.close()
        }
    }
}
