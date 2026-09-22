package com.aurora.store.updates

import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

object ShaheenGitHubUpdater {

    private const val LATEST_RELEASE =
        "https://api.github.com/repos/YS-S1994/SHAHEEN-OS/releases/latest"

    fun check(): ShaheenUpdateInfo? {
        val connection =
            URL(LATEST_RELEASE).openConnection() as HttpURLConnection

        return try {
            connection.requestMethod = "GET"
            connection.connectTimeout = 15000
            connection.readTimeout = 20000
            connection.setRequestProperty(
                "Accept",
                "application/vnd.github+json"
            )
            connection.setRequestProperty(
                "User-Agent",
                "SHAHEEN-OS"
            )

            if (connection.responseCode !in 200..299) return null

            val body = connection.inputStream
                .bufferedReader()
                .use { it.readText() }

            val root = JSONObject(body)

            val tag = root.optString("tag_name")
            if (tag.isBlank()) return null

            val assets = root.optJSONArray("assets")
                ?: return null

            var apkUrl: String? = null
            var sha256: String? = null

            for (i in 0 until assets.length()) {
                val asset = assets.getJSONObject(i)
                val name = asset.optString("name")

                if (name.endsWith(".apk", ignoreCase = true)) {
                    apkUrl = asset.optString("browser_download_url")

                    sha256 = asset.optString("digest")
                        .removePrefix("sha256:")
                        .ifBlank { null }

                    break
                }
            }

            val url = apkUrl ?: return null

            ShaheenUpdateInfo(
                versionName = tag.removePrefix("v"),
                versionCode = null,
                downloadUrl = url,
                releaseUrl = root.optString("html_url")
                    .ifBlank { null },
                sha256 = sha256,
                releaseNotes = root.optString("body")
                    .ifBlank { null }
            )
        } finally {
            connection.disconnect()
        }
    }
}
