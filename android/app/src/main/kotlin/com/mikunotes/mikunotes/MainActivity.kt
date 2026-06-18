package com.mikunotes.mikunotes

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        const val CHANNEL = "mikunotes/bg_service"
        const val NOTIFICATION_CHANNEL_ID = "mikunotes_summary"
        var instance: MainActivity? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        instance = this
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val title = call.argument<String>("title") ?: "MikuNotes"
                    val text = call.argument<String>("text") ?: "正在生成总结..."
                    startForegroundService(title, text)
                    result.success(true)
                }
                "updateNotification" -> {
                    val title = call.argument<String>("title") ?: ""
                    val text = call.argument<String>("text") ?: ""
                    updateNotification(title, text)
                    result.success(true)
                }
                "stopService" -> {
                    stopService()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startForegroundService(title: String, text: String) {
        createNotificationChannel()
        val intent = Intent(this, SummaryForegroundService::class.java)
        intent.putExtra("title", title)
        intent.putExtra("text", text)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun updateNotification(title: String, text: String) {
        SummaryForegroundService.instance?.updateNotification(title, text)
    }

    private fun stopService() {
        val intent = Intent(this, SummaryForegroundService::class.java)
        stopService(intent)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "MikuNotes 总结生成",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "后台生成 AI 总结时的进度通知"
                setSound(null, null)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }
}

class SummaryForegroundService : Service() {
    companion object {
        const val NOTIFICATION_ID = 256
        var instance: SummaryForegroundService? = null
    }

    private var title: String = "MikuNotes"
    private var text: String = "正在生成总结..."

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.let {
            title = it.getStringExtra("title") ?: title
            text = it.getStringExtra("text") ?: text
        }
        startForeground(NOTIFICATION_ID, buildNotification(title, text))
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    fun updateNotification(title: String, text: String) {
        this.title = title
        this.text = text
        val notification = buildNotification(title, text)
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun buildNotification(title: String, text: String): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, MainActivity.NOTIFICATION_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setSilent(true)
            .build()
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }
}
