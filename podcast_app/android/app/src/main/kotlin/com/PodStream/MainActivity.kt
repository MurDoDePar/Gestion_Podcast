package com.podstream

import android.os.Bundle
import android.util.Log
import com.ryanheise.audioservice.AudioServiceActivity
import java.io.File
import java.io.FileWriter
import java.util.Date

class MainActivity: AudioServiceActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        logNative("MainActivity onCreate called")
    }

    private fun logNative(message: String) {
        Log.d("PodStream_Native_Act", message)
        try {
            val logFile = File(filesDir.absolutePath + "/logs_android_auto.txt")
            val writer = FileWriter(logFile, true)
            writer.append("${Date()}: NATIVE_ACT: $message\n")
            writer.flush()
            writer.close()
        } catch (e: Exception) {
            Log.e("PodStream_Native_Act", "Failed to write log", e)
        }
    }
}
