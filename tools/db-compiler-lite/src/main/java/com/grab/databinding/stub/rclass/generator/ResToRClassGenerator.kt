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

package com.grab.databinding.stub.rclass.generator

import com.grab.databinding.stub.common.R_CLASS_OUTPUT
import java.io.File
import com.squareup.javapoet.TypeName.INT
import com.squareup.javapoet.TypeSpec
import com.squareup.javapoet.FieldSpec
import com.squareup.javapoet.JavaFile
import com.grab.databinding.stub.common.Generator
import com.grab.databinding.stub.common.OUTPUT
import javax.inject.Named
import javax.inject.Singleton
import com.grab.databinding.stub.rclass.parser.ResToRParser
import javax.lang.model.element.Modifier.*
import java.util.zip.ZipFile
import java.nio.file.Files
import java.nio.file.Paths
import com.squareup.javapoet.ArrayTypeName

interface ResToRClassGenerator : Generator {
    override val defaultDirName get() = R_CLASS_OUTPUT
    fun generate(packageName: String, fileRes: List<File>, rTxtZip: File)
}

@Singleton
class ResToRClassGeneratorImpl constructor(
        private val resToRParser: ResToRParser,
        @Named(OUTPUT) override val preferredDir: File?
) : ResToRClassGenerator {

    private val rTxtDir = Paths.get("rTxts").let { Files.createDirectories(it) }

    override fun generate(packageName: String, fileRes: List<File>, rTxtZip: File) {

        val resources = resToRParser.parse(fileRes, unzipRTxtDeps(rTxtZip))

        val subclasses = mutableListOf<TypeSpec>()

        resources.keys.forEach { key ->
            val fields = mutableListOf<FieldSpec>()

            resources.get(key)
                    ?.asSequence()
                    ?.distinctBy { it.name }
                    ?.forEach {
                        val type = when {
                            it.isArray -> ArrayTypeName.of(INT)
                            else -> INT
                        }
                        val modifiers = mutableListOf(PUBLIC, STATIC).apply { if (it.isArray) add(FINAL) }.toTypedArray()

                        fields.add(FieldSpec.builder(type, it.name)
                                .addModifiers(*modifiers)
                                .initializer(it.value)
                                .build())
                    }

            subclasses.add(TypeSpec.classBuilder(key.entry)
                    .addFields(fields)
                    .addModifiers(PUBLIC, STATIC, FINAL)
                    .build())
        }

        TypeSpec.classBuilder("R")
                .addTypes(subclasses)
                .addModifiers(FINAL, PUBLIC)
                .build()
                .let { type ->
                    JavaFile.builder(packageName, type)
                            .build()
                            .writeTo(outputDir)
                    logFile(packageName, type.name)
                }
    }

    private fun unzipRTxtDeps(rTxtZip: File): List<String> {
        val content = mutableListOf<String>()

        //unzip: R.txt files and parse one by one
        ZipFile(rTxtZip).use { zip ->
            zip.entries().asSequence().forEach { entry ->
                zip.getInputStream(entry).use { input ->
                    val extractedFile = File(rTxtDir.toFile(), entry.name).apply {
                        parentFile?.mkdirs()
                    }
                    extractedFile
                            .outputStream()
                            .use { output -> input.copyTo(output) }
                    extractedFile.readLines()
                            .filter { it.isNotEmpty() }
                            .let { content.addAll(it) }
                }
            }
        }
        return content
    }
}