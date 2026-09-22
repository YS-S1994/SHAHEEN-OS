package com.aurora.store.updates

import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

object ShaheenServerUpdater {

    private const val MANIFEST =
        "https://shaheen94s.mooo.com/shaheen-os/update.json"

    fun check(): ShaheenUpdateInfo? {
        val connection =
            URL(MANIFEST).openConnection() as HttpURLConnection

        return try {
            connection.requestMethod = "GET"
            connection.connectTimeout = 15000
            connection.readTimeout = 20000
            connection.setRequestProperty(
                "User-Agent",
                "SHAHEEN-OS"
            )

            if (connection.responseCode !in 200..299) return null

            val body = connection.inputStream
                .bufferedReader()
                .use { it.readText() }

            val json = JSONObject(body)

            val versionName =
                json.optString("versionName")

            val downloadUrl =
                json.optString("downloadUrl")

            if (versionName.isBlank() ||
                downloadUrl.isBlank()
            ) {
                return null
            }

            ShaheenUpdateInfo(
                versionName = versionName,
                versionCode =
                    if (json.has("versionCode"))
                        json.optLong("versionCode")
                    else null,
                downloadUrl = downloadUrl,
                releaseUrl =
                    json.optString("releaseUrl")
                        .ifBlank { null },
                sha256 =
                    json.optString("sha256")
                        .ifBlank { null },
                releaseNotes =
                    json.optString("releaseNotes")
                        .ifBlank { null },
                mandatory =
                    json.optBoolean("mandatory", false)
            )
        } finally {
            connection.disconnect()
        }
    }
}
