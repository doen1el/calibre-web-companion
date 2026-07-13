package de.doen1el.calibreWebCompanion

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import java.io.File
import kotlin.math.sqrt

private const val MIN_COVER_DIMEN = 96
private const val MAX_COVER_DIMEN = 256

class ShelfWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        ShelfRemoteViewsFactory(applicationContext)
}

private data class ShelfItem(
    val uuid: String,
    val title: String,
    val authors: String,
    val cover: String
)

private class ShelfRemoteViewsFactory(private val context: Context) :
    RemoteViewsService.RemoteViewsFactory {

    private var items: List<ShelfItem> = emptyList()
    private var palette: WidgetTheming.Palette? = null
    private var coverDimen: Int = MAX_COVER_DIMEN

    override fun onCreate() = Unit

    override fun onDataSetChanged() {
        val data = HomeWidgetPlugin.getData(context)
        items = parse(data.getString("sh_json", "") ?: "")
        palette = WidgetTheming.palette(context, data)
        coverDimen = coverDimenFor(items.size)
    }

    private fun coverDimenFor(count: Int): Int {
        if (count <= 0) return MAX_COVER_DIMEN

        val metrics = context.resources.displayMetrics
        val hostLimit =
            metrics.widthPixels.toLong() * metrics.heightPixels.toLong() * 4L * 3L / 2L
        val perItem = hostLimit * 30 / 100 / count
        val height = sqrt(perItem / 2.7).toInt()

        return height.coerceIn(MIN_COVER_DIMEN, MAX_COVER_DIMEN)
    }

    override fun onDestroy() {
        items = emptyList()
    }

    override fun getCount(): Int = items.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_shelf_item)
        val item = items.getOrNull(position) ?: return views

        views.setTextViewText(R.id.item_title, item.title)
        views.setTextViewText(R.id.item_authors, item.authors)
        views.setContentDescription(R.id.item_cover, item.title)

        val decoded =
            if (item.cover.isNotEmpty() && File(item.cover).exists()) {
                WidgetImages.decodeScaledCover(item.cover, maxDimen = coverDimen)
            } else {
                null
            }
        if (decoded != null) {
            val radius = 8f * context.resources.displayMetrics.density
            views.setImageViewBitmap(R.id.item_cover, WidgetImages.roundBitmap(decoded, radius))
        } else {
            views.setImageViewResource(R.id.item_cover, R.drawable.widget_cover_placeholder)
        }

        palette?.let { p ->
            views.setTextColor(R.id.item_title, p.onBackground)
            views.setTextColor(R.id.item_authors, WidgetTheming.muted(p.onBackground))
        }

        val target = "calibrewebcompanion://widget/book?uuid=${item.uuid}"
        views.setOnClickFillInIntent(
            R.id.item_root,
            Intent()
                .setData(Uri.parse(target))
                .putExtra(MainActivity.EXTRA_WIDGET_URI, target)
        )

        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true

    private fun parse(json: String): List<ShelfItem> {
        if (json.isEmpty()) return emptyList()
        return runCatching {
            val array = JSONArray(json)
            (0 until array.length()).mapNotNull { index ->
                val entry = array.optJSONObject(index) ?: return@mapNotNull null
                ShelfItem(
                    uuid = entry.optString("uuid"),
                    title = entry.optString("title"),
                    authors = entry.optString("authors"),
                    cover = entry.optString("cover")
                )
            }
        }.getOrDefault(emptyList())
    }
}
