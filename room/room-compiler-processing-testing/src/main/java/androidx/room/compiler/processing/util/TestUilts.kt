/*
 * Copyright 2021 The Android Open Source Project
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

package androidx.room.compiler.processing.util

import java.io.File
import java.util.Locale
import javax.tools.Diagnostic
import javax.tools.JavaFileObject

/**
 * Returns the list of File's in the system classpath
 *
 * @see getSystemClasspaths
 */
fun getSystemClasspathFiles(): Set<File> {
    return getSystemClasspaths().map { File(it) }.toSet()
}

/**
 * Returns the file paths from the system class loader
 *
 * @see getSystemClasspathFiles
 */
fun getSystemClasspaths(): Set<String> {
    val pathSeparator = System.getProperty("path.separator")!!
    return System.getProperty("java.class.path")!!.split(pathSeparator).toSet()
}

/** Converts java compilation diagnostic messages into [DiagnosticMessage] objects. */
internal fun List<Diagnostic<out JavaFileObject>>.toDiagnosticMessages(
    javaSources: Map<JavaFileObject, Source>
): List<DiagnosticMessage> {
    return this.map { diagnostic ->
        val source = diagnostic.source?.let { javaSources[it] }
        val location =
            if (source == null) {
                null
            } else {
                DiagnosticLocation(
                    source = source,
                    line = diagnostic.lineNumber.toInt(),
                )
            }
        DiagnosticMessage(
            kind = diagnostic.kind,
            msg = diagnostic.getMessage(Locale.US),
            location = location,
        )
    }
}
