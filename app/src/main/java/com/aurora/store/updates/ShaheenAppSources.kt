package com.aurora.store.updates

data class ShaheenAppSource(
    val name: String,
    val type: String,
    val enabled: Boolean,
    val priority: Int
)

object ShaheenAppSources {

    val sources = listOf(
        ShaheenAppSource(
            name = "GitHub",
            type = "github",
            enabled = true,
            priority = 1
        ),
        ShaheenAppSource(
            name = "F-Droid",
            type = "fdroid",
            enabled = true,
            priority = 2
        ),
        ShaheenAppSource(
            name = "Uptodown",
            type = "uptodown",
            enabled = true,
            priority = 3
        ),
        ShaheenAppSource(
            name = "Google Play",
            type = "google_play",
            enabled = true,
            priority = 4
        ),
        ShaheenAppSource(
            name = "Google Chrome",
            type = "web",
            enabled = true,
            priority = 5
        ),
        ShaheenAppSource(
            name = "App Store",
            type = "ios_reference",
            enabled = true,
            priority = 6
        ),
        ShaheenAppSource(
            name = "Official Developer",
            type = "official",
            enabled = true,
            priority = 7
        )
    ).sortedBy { it.priority }
}
