/*
 * Copyright 2022 The Android Open Source Project
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

package androidx.compose.foundation.samples

import androidx.annotation.Sampled
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.foundation.lazy.grid.LazyHorizontalGrid
import androidx.compose.foundation.lazy.grid.LazyLayoutAnimateScrollScope
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.Button
import androidx.compose.material.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch

@Sampled
@Composable
fun LazyVerticalGridSample() {
    val itemsList = (0..5).toList()
    val itemsIndexedList = listOf("A", "B", "C")

    val itemModifier = Modifier.border(1.dp, Color.Blue).height(80.dp).wrapContentSize()

    LazyVerticalGrid(columns = GridCells.Fixed(3)) {
        items(itemsList) { Text("Item is $it", itemModifier) }
        item { Text("Single item", itemModifier) }
        itemsIndexed(itemsIndexedList) { index, item ->
            Text("Item at index $index is $item", itemModifier)
        }
    }
}

@Sampled
@Composable
fun LazyVerticalGridSpanSample() {
    val sections = (0 until 25).toList().chunked(5)
    LazyVerticalGrid(
        columns = GridCells.Fixed(3),
        horizontalArrangement = Arrangement.spacedBy(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        sections.forEachIndexed { index, items ->
            item(span = { GridItemSpan(maxLineSpan) }) {
                Text(
                    "This is section $index",
                    Modifier.border(1.dp, Color.Gray).height(80.dp).wrapContentSize()
                )
            }
            items(
                items,
                // not required as it is the default
                span = { GridItemSpan(1) }
            ) {
                Text("Item $it", Modifier.border(1.dp, Color.Blue).height(80.dp).wrapContentSize())
            }
        }
    }
}

@Sampled
@Composable
fun LazyHorizontalGridSample() {
    val itemsList = (0..5).toList()
    val itemsIndexedList = listOf("A", "B", "C")

    val itemModifier = Modifier.border(1.dp, Color.Blue).width(80.dp).wrapContentSize()

    LazyHorizontalGrid(
        rows = GridCells.Fixed(3),
        horizontalArrangement = Arrangement.spacedBy(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        items(itemsList) { Text("Item is $it", itemModifier) }

        item { Text("Single item", itemModifier) }

        itemsIndexed(itemsIndexedList) { index, item ->
            Text("Item at index $index is $item", itemModifier)
        }
    }
}

@Sampled
@Composable
fun LazyHorizontalGridSpanSample() {
    val sections = (0 until 25).toList().chunked(5)
    LazyHorizontalGrid(
        rows = GridCells.Fixed(3),
        horizontalArrangement = Arrangement.spacedBy(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        sections.forEachIndexed { index, items ->
            item(span = { GridItemSpan(maxLineSpan) }) {
                Text(
                    "This is section $index",
                    Modifier.border(1.dp, Color.Gray).width(80.dp).wrapContentSize()
                )
            }
            items(
                items,
                // not required as it is the default
                span = { GridItemSpan(1) }
            ) {
                Text("Item $it", Modifier.border(1.dp, Color.Blue).width(80.dp).wrapContentSize())
            }
        }
    }
}

@Sampled
@Composable
fun UsingGridScrollPositionForSideEffectSample() {
    val gridState = rememberLazyGridState()
    LaunchedEffect(gridState) {
        snapshotFlow { gridState.firstVisibleItemIndex }
            .collect {
                // use the new index
            }
    }
}

@Sampled
@Composable
fun UsingGridScrollPositionInCompositionSample() {
    val gridState = rememberLazyGridState()
    val isAtTop by remember {
        derivedStateOf {
            gridState.firstVisibleItemIndex == 0 && gridState.firstVisibleItemScrollOffset == 0
        }
    }
    if (!isAtTop) {
        ScrollToTopButton(gridState)
    }
}

@Sampled
@Composable
fun UsingGridLayoutInfoForSideEffectSample() {
    val gridState = rememberLazyGridState()
    LaunchedEffect(gridState) {
        snapshotFlow { gridState.layoutInfo.totalItemsCount }
            .collect {
                // use the new items count
            }
    }
}

@Sampled
@Composable
fun GridAnimateItemSample() {
    var list by remember { mutableStateOf(listOf("A", "B", "C")) }
    Column {
        Button(onClick = { list = list + "D" }) { Text("Add new item") }
        Button(onClick = { list = list.shuffled() }) { Text("Shuffle") }
        LazyVerticalGrid(columns = GridCells.Fixed(1)) {
            items(list, key = { it }) { Text("Item $it", Modifier.animateItem()) }
        }
    }
}

@Composable private fun ScrollToTopButton(@Suppress("UNUSED_PARAMETER") gridState: LazyGridState) {}

@Sampled
@Composable
fun CustomLazyGridAnimateToItemScrollSample() {
    val itemsList = (0..100).toList()
    val state = rememberLazyGridState()
    val scope = rememberCoroutineScope()
    val animatedScrollScope = remember(state) { LazyLayoutAnimateScrollScope(state) }

    Column(Modifier.verticalScroll(rememberScrollState())) {
        Button(
            onClick = {
                scope.launch {
                    state.scroll {
                        with(animatedScrollScope) {
                            snapToItem(40, 0) // teleport to item 40
                            val distance = calculateDistanceTo(50).toFloat()
                            var previousValue = 0f
                            androidx.compose.animation.core.animate(
                                0f,
                                distance,
                                animationSpec = tween(5_000)
                            ) { currentValue, _ ->
                                previousValue += scrollBy(currentValue - previousValue)
                            }
                        }
                    }
                }
            }
        ) {
            Text("Scroll To Item 50")
        }
        LazyHorizontalGrid(
            state = state,
            rows = GridCells.Fixed(3),
            modifier = Modifier.height(600.dp).fillMaxWidth()
        ) {
            items(itemsList) {
                Box(Modifier.padding(2.dp).background(Color.Red).size(45.dp)) {
                    Text(it.toString())
                }
            }
        }
    }
}
