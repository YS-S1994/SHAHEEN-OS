package com.aurora.store.compose.ui.shaheen

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.aurora.store.BuildConfig
import com.aurora.store.updates.ShaheenUpdateInfo
import com.aurora.store.updates.ShaheenUpdaterRepository
import kotlinx.coroutines.launch

@Composable
fun ShaheenUpdaterScreen() {

    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    var checking by remember { mutableStateOf(false) }
    var update by remember { mutableStateOf<ShaheenUpdateInfo?>(null) }
    var message by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(Unit) {
        checking = true
        update = runCatching {
            ShaheenUpdaterRepository.check(context)
        }.getOrNull()
        checking = false

        if (update == null) {
            message = "SHAHEEN-OS is up to date."
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {

        Text(
            text = "SHAHEEN-OS Auto Updater",
            style = MaterialTheme.typography.headlineSmall
        )

        Text(
            text = "Installed version: ${BuildConfig.VERSION_NAME}"
        )

        if (checking) {
            CircularProgressIndicator()
            Text("Checking GitHub and the official SHAHEEN server...")
        }

        update?.let { info ->

            Text(
                text = "New version available: ${info.versionName}",
                style = MaterialTheme.typography.titleMedium
            )

            info.releaseNotes?.takeIf { it.isNotBlank() }?.let {
                Text(it)
            }

            Button(
                modifier = Modifier.fillMaxWidth(),
                onClick = {
                    val intent = Intent(
                        Intent.ACTION_VIEW,
                        Uri.parse(info.downloadUrl)
                    )
                    context.startActivity(intent)
                }
            ) {
                Text("Download update")
            }

            info.releaseUrl?.let { url ->
                Button(
                    modifier = Modifier.fillMaxWidth(),
                    onClick = {
                        context.startActivity(
                            Intent(
                                Intent.ACTION_VIEW,
                                Uri.parse(url)
                            )
                        )
                    }
                ) {
                    Text("Open release")
                }
            }
        }

        message?.let {
            Text(
                text = it,
                style = MaterialTheme.typography.bodyLarge
            )
        }

        Button(
            modifier = Modifier.fillMaxWidth(),
            enabled = !checking,
            onClick = {
                scope.launch {
                    checking = true
                    message = null
                    update =
                        runCatching {
                            ShaheenUpdaterRepository.check(context)
                        }.getOrNull()
                    checking = false

                    if (update == null) {
                        message = "No newer SHAHEEN-OS release was found."
                    }
                }
            }
        ) {
            Text("Check for updates")
        }
    }
}
