/*
 * Copyright 2021 Grabtaxi Holdings PTE LTE (GRAB)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.grab.databinding.stub

import com.github.ajalt.clikt.core.CliktCommand
import com.github.ajalt.clikt.parameters.options.*
import java.io.File

class BindingStubCommand : CliktCommand() {

    private val layoutFiles by option(
        "-l",
        "--layouts",
        help = "List of layout files"
    ).split(",").default(emptyList())

    private val resources by option(
        "-res",
        "--resources",
        help = "List of module res files"
    ).split(",").default(emptyList())

    private val packageName by option(
        "-p",
        "--package",
        help = "Package name of R class"
    ).required()

    private val src by option(
        "-s",
        "--src",
        help = "The source package of the given layout files to process"
    ).required()

    private val debug by option(
        "-d",
        "--debug",
        help = "Run the binary in debug mode which takes absolute paths for layout files"
    ).flag(default = false)

    private val preferredOutputDir by option(
        "-o",
        "--output"
    ).convert { File(it) }

    private val dependencyClassInfoZip: File by option(
        "-cl",
        "--class-info",
        help = "Path to class-info.zip containing list of binding-clasess.json from direct dependencies"
    ).convert { File(it) }.required()

    private val rTxtZip by option(
            "-r",
            "--r-txt-deps",
            help = "Zip of R txt files from deps aar"
    ).convert { File(it) }.required()

    override fun run() {
        val layoutFiles = layoutFiles.map { file ->
            when {
                debug -> File(file)
                else -> File("$src/$file")
            }
        }

        val resourcesFiles = resources.map { file ->
            when {
                debug -> File(file)
                else -> File("$src/$file")
            }
        }

        DaggerBindingsStubComponent
            .factory()
            .create(
                preferredOutputDir,
                packageName,
                layoutFiles,
                resourcesFiles,
                dependencyClassInfoZip,
                rTxtZip
            ).apply {
                val layoutBindings = layoutBindingsParser().parse(packageName, layoutFiles)
                resToRClassGenerator().generate(packageName, resourcesFiles, rTxtZip)
                brClassGenerator().generate(packageName, layoutBindings)
                bindingClassGenerator().generate(packageName, layoutBindings)
            }
    }
}