package de.doen1el.calibreWebCompanion

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class ShelfWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_shelf)

            val title = widgetData.getString("sh_title", "") ?: ""
            views.setTextViewText(
                R.id.shelf_title,
                if (title.isEmpty()) context.getString(R.string.widget_shelf_recent) else title
            )

            val adapterIntent = Intent(context, ShelfWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                // Makes the intent unique per widget so each keeps its own adapter.
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            views.setRemoteAdapter(R.id.shelf_grid, adapterIntent)
            views.setEmptyView(R.id.shelf_grid, R.id.shelf_empty)

            val template = Intent(context, MainActivity::class.java).apply {
                action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
            }
            views.setPendingIntentTemplate(
                R.id.shelf_grid,
                PendingIntent.getActivity(
                    context,
                    0,
                    template,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                )
            )

            WidgetTheming.palette(context, widgetData)?.let { p ->
                views.setInt(R.id.widget_bg, "setColorFilter", p.background)
                views.setTextColor(R.id.shelf_title, p.onBackground)
                views.setTextColor(R.id.shelf_empty, WidgetTheming.muted(p.onBackground))
                views.setInt(R.id.shelf_refresh, "setColorFilter", p.accent)
            }

            // Reloads the shelf in a background isolate, without opening the app.
            val refresh = HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse("calibrewebcompanion://widget/refresh")
            )
            views.setOnClickPendingIntent(R.id.shelf_refresh, refresh)
            views.setOnClickPendingIntent(R.id.shelf_empty, refresh)

            views.setOnClickPendingIntent(
                R.id.shelf_header,
                HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("calibrewebcompanion://widget/shelf")
                )
            )

            appWidgetManager.updateAppWidget(widgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.shelf_grid)
        }
    }
}
