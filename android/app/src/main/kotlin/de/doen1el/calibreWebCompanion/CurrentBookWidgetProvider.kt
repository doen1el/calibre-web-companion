package de.doen1el.calibreWebCompanion

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

class CurrentBookWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_current_book)

            val uuid = widgetData.getString("cb_uuid", "") ?: ""
            val title = widgetData.getString("cb_title", "") ?: ""
            val authors = widgetData.getString("cb_authors", "") ?: ""
            val coverPath = widgetData.getString("cb_cover", "") ?: ""
            val progress = (widgetData.getString("cb_progress", "0") ?: "0").toIntOrNull() ?: 0

            if (uuid.isEmpty()) {
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
                views.setViewVisibility(R.id.widget_content, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_empty, View.GONE)
                views.setViewVisibility(R.id.widget_content, View.VISIBLE)
                views.setTextViewText(R.id.widget_title, title)
                views.setTextViewText(R.id.widget_authors, authors)

                val decoded =
                    if (coverPath.isNotEmpty() && File(coverPath).exists()) {
                        WidgetImages.decodeScaledCover(coverPath)
                    } else {
                        null
                    }
                if (decoded != null) {
                    val radius = 10f * context.resources.displayMetrics.density
                    views.setImageViewBitmap(
                        R.id.widget_cover,
                        WidgetImages.roundBitmap(decoded, radius)
                    )
                } else {
                    views.setImageViewResource(R.id.widget_cover, R.drawable.widget_cover_placeholder)
                }

                if (progress in 1..99) {
                    views.setViewVisibility(R.id.widget_percent_container, View.VISIBLE)
                    views.setTextViewText(R.id.widget_percent, "$progress%")
                } else {
                    views.setViewVisibility(R.id.widget_percent_container, View.GONE)
                }
            }

            WidgetTheming.palette(context, widgetData)?.let { p ->
                views.setInt(R.id.widget_bg, "setColorFilter", p.background)
                views.setTextColor(R.id.widget_title, p.onBackground)
                views.setTextColor(R.id.widget_empty, p.onBackground)
                views.setTextColor(R.id.widget_authors, WidgetTheming.muted(p.onBackground))
                views.setInt(R.id.widget_percent_bg, "setColorFilter", p.accent)
                views.setTextColor(R.id.widget_percent, p.onAccent)
            }

            val uri = Uri.parse("calibrewebcompanion://widget/current?uuid=$uuid")
            val pendingIntent =
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, uri)
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
