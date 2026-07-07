package de.doen1el.calibreWebCompanion

import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Color
import android.widget.RemoteViews

object WidgetTheming {
    fun apply(
        context: Context,
        views: RemoteViews,
        widgetData: SharedPreferences,
        bgViewId: Int,
        primaryTextIds: IntArray,
        secondaryTextIds: IntArray
    ) {
        val night = (context.resources.configuration.uiMode and
            Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
        val suffix = if (night) "dark" else "light"

        val bg = widgetData.getString("th_bg_$suffix", null)
        val onBg = widgetData.getString("th_on_bg_$suffix", null)
        if (bg.isNullOrEmpty() || onBg.isNullOrEmpty()) return

        val bgColor = runCatching { Color.parseColor(bg) }.getOrNull() ?: return
        val onBgColor = runCatching { Color.parseColor(onBg) }.getOrNull() ?: return

        views.setInt(bgViewId, "setColorFilter", bgColor)
        for (id in primaryTextIds) views.setTextColor(id, onBgColor)

        val secondary = (onBgColor and 0x00FFFFFF) or (0xB3 shl 24)
        for (id in secondaryTextIds) views.setTextColor(id, secondary)
    }
}
