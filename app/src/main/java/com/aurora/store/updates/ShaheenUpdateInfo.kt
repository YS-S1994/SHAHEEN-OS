package com.aurora.store.updates

data class ShaheenUpdateInfo(
    val versionName: String,
    val versionCode: Long?,
    val downloadUrl: String,
    val releaseUrl: String?,
    val sha256: String?,
    val releaseNotes: String? = null,
    val mandatory: Boolean = false
)
