package com.aurora.store.updates

import android.content.Context
import android.content.pm.PackageManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

object ShaheenUpdaterRepository {

    suspend fun check(context: Context): ShaheenUpdateInfo? =
        withContext(Dispatchers.IO) {
            val installedCode = installedVersionCode(context)
            val installedName = installedVersionName(context)

            val candidates = listOfNotNull(
                runCatching {
                    ShaheenGitHubUpdater.check()
                }.getOrNull(),
                runCatching {
                    ShaheenServerUpdater.check()
                }.getOrNull()
            )

            candidates
                .sortedByDescending {
                    it.versionCode ?: versionCodeFromName(it.versionName)
                }
                .firstOrNull { update ->
                    val remoteCode =
                        update.versionCode
                            ?: versionCodeFromName(update.versionName)

                    val installed =
                        installedCode
                            ?: versionCodeFromName(installedName)

                    remoteCode > installed
                }
        }

    private fun installedVersionCode(context: Context): Long? {
        return runCatching {
            val info = context.packageManager
                .getPackageInfo(context.packageName, 0)

            if (android.os.Build.VERSION.SDK_INT >= 28) {
                info.longVersionCode
            } else {
                @Suppress("DEPRECATION")
                info.versionCode.toLong()
            }
        }.getOrNull()
    }

    private fun installedVersionName(context: Context): String {
        return runCatching {
            context.packageManager
                .getPackageInfo(context.packageName, 0)
                .versionName ?: "0"
        }.getOrDefault("0")
    }

    private fun versionCodeFromName(version: String): Long {
        return version
            .removePrefix("v")
            .substringBefore("-")
            .split(".")
            .take(4)
            .fold(0L) { result, part ->
                result * 1000L +
                    (part.toLongOrNull() ?: 0L)
            }
    }
}
