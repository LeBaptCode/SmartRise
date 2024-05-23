package com.example.smart_rise

import android.content.Context
import android.media.RingtoneManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = "flutter_channel"

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            when (call.method) {
                "getRingtones" -> {
                    val ringtones = getAllRingtones(this)
                    result.success(ringtones)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getAllRingtones(context: Context): List<String> {
        val ringtoneManager = RingtoneManager(context)
        ringtoneManager.setType(RingtoneManager.TYPE_RINGTONE)
        val cursor = ringtoneManager.cursor
        val ringtoneList = mutableListOf<String>()
        while (cursor.moveToNext()) {
            val ringtoneTitle = cursor.getString(RingtoneManager.TITLE_COLUMN_INDEX)
            ringtoneList.add(ringtoneTitle)
        }
        cursor.close()
        return ringtoneList
    }
}