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

            WidgetTheming.apply(
                context,
                views,
                widgetData,
                R.id.widget_bg,
                intArrayOf(
                    R.id.stat_books_value,
                    R.id.stat_authors_value,
                    R.id.stat_categories_value,
                    R.id.stat_series_value
                ),
                intArrayOf(
                    R.id.stats_label,
                    R.id.stat_books_label,
                    R.id.stat_authors_label,
                    R.id.stat_categories_label,
                    R.id.stat_series_label
                )
            )

            val uri = Uri.parse("calibrewebcompanion://widget/stats")
            val pendingIntent =
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, uri)
            views.setOnClickPendingIntent(R.id.stats_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
