/*
 * Copyright 2024 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package androidx.compose.material3.samples

import androidx.annotation.Sampled
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Anchor
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.outlined.Favorite
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.FilledIconToggleButton
import androidx.compose.material3.FloatingAppBarDefaults
import androidx.compose.material3.FloatingAppBarDefaults.ScreenOffset
import androidx.compose.material3.FloatingAppBarPosition.Companion.Bottom
import androidx.compose.material3.FloatingAppBarPosition.Companion.End
import androidx.compose.material3.HorizontalFloatingAppBar
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.VerticalFloatingAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment.Companion.BottomCenter
import androidx.compose.ui.Alignment.Companion.CenterEnd
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.unit.dp

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Sampled
@Composable
fun HorizontalFloatingAppBar() {
    val listState = rememberLazyListState()
    var currentItem = 0
    val expanded = remember {
        derivedStateOf {
            val temp = currentItem
            currentItem = listState.firstVisibleItemIndex
            listState.firstVisibleItemIndex <= temp
        }
    }
    var anchored by remember { mutableStateOf(false) }
    val exitAlwaysScrollBehavior =
        FloatingAppBarDefaults.exitAlwaysScrollBehavior(position = Bottom)
    Scaffold(
        modifier = Modifier.nestedScroll(exitAlwaysScrollBehavior),
        content = { innerPadding ->
            Box {
                LazyColumn(
                    state = listState,
                    contentPadding = innerPadding,
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    val list = (0..75).map { it.toString() }
                    items(count = list.size) {
                        Text(
                            text = list[it],
                            style = MaterialTheme.typography.bodyLarge,
                            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp)
                        )
                    }
                }
                HorizontalFloatingAppBar(
                    modifier = Modifier.align(BottomCenter).offset(y = -ScreenOffset),
                    expanded = expanded.value,
                    trailingContent = { trailingContent() },
                    leadingContent = {
                        leadingContent()
                        FilledIconToggleButton(
                            checked = anchored,
                            onCheckedChange = { anchored = it }
                        ) {
                            Icon(Icons.Filled.Anchor, contentDescription = "Localized description")
                        }
                    },
                    content = {
                        FilledIconButton(
                            modifier = Modifier.width(64.dp),
                            onClick = { /* doSomething() */ }
                        ) {
                            Icon(
                                Icons.Outlined.Favorite,
                                contentDescription = "Localized description"
                            )
                        }
                    },
                    scrollBehavior = if (!anchored) exitAlwaysScrollBehavior else null
                )
            }
        }
    )
}

@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Sampled
@Composable
fun VerticalFloatingAppBar() {
    val listState = rememberLazyListState()
    var currentItem = 0
    val expanded = remember {
        derivedStateOf {
            val temp = currentItem
            currentItem = listState.firstVisibleItemIndex
            listState.firstVisibleItemIndex <= temp
        }
    }
    var anchored by remember { mutableStateOf(false) }
    val exitAlwaysScrollBehavior = FloatingAppBarDefaults.exitAlwaysScrollBehavior(position = End)
    Scaffold(
        modifier = Modifier.nestedScroll(exitAlwaysScrollBehavior),
        content = { innerPadding ->
            Box {
                LazyColumn(
                    state = listState,
                    contentPadding = innerPadding,
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    val list = (0..75).map { it.toString() }
                    items(count = list.size) {
                        Text(
                            text = list[it],
                            style = MaterialTheme.typography.bodyLarge,
                            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp)
                        )
                    }
                }
                VerticalFloatingAppBar(
                    modifier = Modifier.align(CenterEnd).offset(x = -ScreenOffset),
                    expanded = expanded.value,
                    trailingContent = { trailingContent() },
                    leadingContent = {
                        leadingContent()
                        FilledIconToggleButton(
                            checked = anchored,
                            onCheckedChange = { anchored = it }
                        ) {
                            Icon(Icons.Filled.Anchor, contentDescription = "Localized description")
                        }
                    },
                    content = {
                        FilledIconButton(
                            modifier = Modifier.height(64.dp),
                            onClick = { /* doSomething() */ }
                        ) {
                            Icon(
                                Icons.Outlined.Favorite,
                                contentDescription = "Localized description"
                            )
                        }
                    },
                    scrollBehavior = if (!anchored) exitAlwaysScrollBehavior else null
                )
            }
        }
    )
}

@Composable
private fun trailingContent() {
    IconButton(onClick = { /* doSomething() */ }) {
        Icon(Icons.Filled.Check, contentDescription = "Localized description")
    }
    IconButton(onClick = { /* doSomething() */ }) {
        Icon(Icons.Filled.Edit, contentDescription = "Localized description")
    }
    IconButton(onClick = { /* doSomething() */ }) {
        Icon(Icons.Filled.Download, contentDescription = "Localized description")
    }
}

@Composable
private fun leadingContent() {
    IconButton(onClick = { /* doSomething() */ }) {
        Icon(Icons.Filled.Add, contentDescription = "Localized description")
    }
}
