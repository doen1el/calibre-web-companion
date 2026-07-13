package de.doen1el.calibreWebCompanion

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader

object WidgetImages {
    fun decodeScaledCover(path: String, maxDimen: Int = 512): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

        var sampleSize = 1
        val longestEdge = maxOf(bounds.outWidth, bounds.outHeight)
        while (longestEdge / sampleSize > maxDimen * 2) {
            sampleSize *= 2
        }

        val options = BitmapFactory.Options().apply { inSampleSize = sampleSize }
        val decoded = BitmapFactory.decodeFile(path, options) ?: return null

        val longestDecoded = maxOf(decoded.width, decoded.height)
        if (longestDecoded <= maxDimen) return decoded

        val scale = maxDimen.toFloat() / longestDecoded
        val width = (decoded.width * scale).toInt().coerceAtLeast(1)
        val height = (decoded.height * scale).toInt().coerceAtLeast(1)
        val scaled = Bitmap.createScaledBitmap(decoded, width, height, true)
        if (scaled != decoded) decoded.recycle()
        return scaled
    }

    fun roundBitmap(src: Bitmap, radius: Float): Bitmap {
        val output = Bitmap.createBitmap(src.width, src.height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = BitmapShader(src, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
        }
        val rect = RectF(0f, 0f, src.width.toFloat(), src.height.toFloat())
        canvas.drawRoundRect(rect, radius, radius, paint)
        return output
    }
}
