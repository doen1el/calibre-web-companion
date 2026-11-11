package de.doen1el.calibreWebCompanion

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        SafFileChannel(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        restoreWidgetUri(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        restoreWidgetUri(intent)
        super.onNewIntent(intent)
    }

    private fun restoreWidgetUri(intent: Intent?) {
        if (intent == null) return
        if (intent.action != HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION) return
        if (intent.data != null) return

        val uri = intent.getStringExtra(EXTRA_WIDGET_URI) ?: return
        intent.data = Uri.parse(uri)
    }

    companion object {
        const val EXTRA_WIDGET_URI = "widget_uri"
    }
}
