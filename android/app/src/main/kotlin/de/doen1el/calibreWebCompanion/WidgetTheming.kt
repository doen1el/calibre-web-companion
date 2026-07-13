package de.doen1el.calibreWebCompanion

import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Color

object WidgetTheming {
    data class Palette(
        val background: Int,
        val onBackground: Int,
        val tile: Int,
        val onTile: Int,
        val accent: Int,
        val onAccent: Int
    )

    fun palette(context: Context, data: SharedPreferences): Palette? {
        val night = (context.resources.configuration.uiMode and
            Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
        val suffix = if (night) "dark" else "light"

        val background = parse(data, "th_bg_$suffix") ?: return null
        val onBackground = parse(data, "th_on_bg_$suffix") ?: return null
        val tile = parse(data, "th_tile_$suffix") ?: background
        val onTile = parse(data, "th_on_tile_$suffix") ?: onBackground
        val accent = parse(data, "th_accent_$suffix") ?: onBackground
        val onAccent = parse(data, "th_on_accent_$suffix") ?: background

        return Palette(background, onBackground, tile, onTile, accent, onAccent)
    }

    fun muted(color: Int): Int = (color and 0x00FFFFFF) or (0xB3 shl 24)

    private fun parse(data: SharedPreferences, key: String): Int? =
        data.getString(key, null)?.let { runCatching { Color.parseColor(it) }.getOrNull() }
}
