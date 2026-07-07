package de.doen1el.calibreWebCompanion

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class LibraryStatsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_library_stats)

            views.setTextViewText(R.id.stat_books_value, widgetData.getString("st_books", "0"))
            views.setTextViewText(R.id.stat_authors_value, widgetData.getString("st_authors", "0"))
            views.setTextViewText(
                R.id.stat_categories_value,
                widgetData.getString("st_categories", "0")
            )
            views.setTextViewText(R.id.stat_series_value, widgetData.getString("st_series", "0"))

            WidgetTheming.palette(context, widgetData)?.let { p ->
                views.setInt(R.id.widget_bg, "setColorFilter", p.background)
                views.setTextColor(R.id.stats_label, WidgetTheming.muted(p.onBackground))

                for (tileBg in intArrayOf(
                    R.id.tile_bg_books,
                    R.id.tile_bg_authors,
                    R.id.tile_bg_categories,
                    R.id.tile_bg_series
                )) {
                    views.setInt(tileBg, "setColorFilter", p.tile)
                }
                for (value in intArrayOf(
                    R.id.stat_books_value,
                    R.id.stat_authors_value,
                    R.id.stat_categories_value,
                    R.id.stat_series_value
                )) {
                    views.setTextColor(value, p.onTile)
                }
                for (label in intArrayOf(
                    R.id.stat_books_label,
                    R.id.stat_authors_label,
                    R.id.stat_categories_label,
                    R.id.stat_series_label
                )) {
                    views.setTextColor(label, WidgetTheming.muted(p.onTile))
                }
            }

            val uri = Uri.parse("calibrewebcompanion://widget/stats")
            val pendingIntent =
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, uri)
            views.setOnClickPendingIntent(R.id.stats_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
