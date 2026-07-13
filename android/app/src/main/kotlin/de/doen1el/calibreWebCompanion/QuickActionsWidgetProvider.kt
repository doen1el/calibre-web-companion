package de.doen1el.calibreWebCompanion

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class QuickActionsWidgetProvider : HomeWidgetProvider() {

    private data class Action(
        val slotId: Int,
        val tileId: Int,
        val iconId: Int,
        val labelId: Int,
        val key: String
    )

    private val actions = listOf(
        Action(R.id.qa_slot_search, R.id.qa_tile_search, R.id.qa_icon_search, R.id.qa_label_search, "search"),
        Action(R.id.qa_slot_scan, R.id.qa_tile_scan, R.id.qa_icon_scan, R.id.qa_label_scan, "scan"),
        Action(R.id.qa_slot_read, R.id.qa_tile_read, R.id.qa_icon_read, R.id.qa_label_read, "read"),
        Action(R.id.qa_slot_downloads, R.id.qa_tile_downloads, R.id.qa_icon_downloads, R.id.qa_label_downloads, "downloads")
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val downloadsEnabled = widgetData.getString("qa_downloads", "0") == "1"
        val palette = WidgetTheming.palette(context, widgetData)

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_quick_actions)

            palette?.let { views.setInt(R.id.widget_bg, "setColorFilter", it.background) }

            for (action in actions) {
                if (action.key == "downloads" && !downloadsEnabled) {
                    views.setViewVisibility(action.slotId, View.GONE)
                    continue
                }

                views.setViewVisibility(action.slotId, View.VISIBLE)
                views.setOnClickPendingIntent(
                    action.slotId,
                    HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("calibrewebcompanion://widget/action?do=${action.key}")
                    )
                )

                palette?.let { p ->
                    views.setInt(action.tileId, "setColorFilter", p.tile)
                    views.setInt(action.iconId, "setColorFilter", p.onTile)
                    views.setTextColor(action.labelId, p.onBackground)
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
