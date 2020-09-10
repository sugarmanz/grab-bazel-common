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

package com.grab.databinding.stub.binding.generator

import com.grab.databinding.stub.binding.parser.Binding
import com.grab.databinding.stub.binding.parser.BindingType
import com.grab.databinding.stub.binding.parser.LayoutBindingData
import com.grab.databinding.stub.common.BaseBindingStubTest
import com.grab.databinding.stub.common.DB_STUBS_OUTPUT
import com.squareup.javapoet.ClassName
import org.junit.Before
import org.junit.Test
import java.io.File
import java.nio.file.Paths
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class DefaultBindingClassGeneratorTest : BaseBindingStubTest() {

    private lateinit var defaultBindingClassGenerator: DefaultBindingClassGenerator
    private lateinit var outputDir: File
    private lateinit var layoutBinding: LayoutBindingData

    private val testPackage = "test"
    private val className = "com.package.Class"
    private val layoutName = "SimpleBinding"
    private val bindableName = "vm"
    private val bindableNameWithUnderscoe = "vm_test"
    private val bindingName = "time_display"
    private val bindingFragmentRawName = "fragment_view"

    private val generatedFileContents
        get() = File(
            outputDir,
            Paths.get(
                DB_STUBS_OUTPUT,
                testPackage,
                "databinding",
                "$layoutName.java"
            ).toString()
        ).readText()

    @Before
    fun setup() {
        outputDir = temporaryFolder.newFolder()
        defaultBindingClassGenerator = DefaultBindingClassGenerator(outputDir)
        val testClassName = ClassName.bestGuess(className)
        layoutBinding = LayoutBindingData(
            layoutName = layoutName,
            file = temporaryFolder.newFile("simple_binding.xml").apply {
                writeText(
                    """
                    <layout xmlns:android="http://schemas.android.com/apk/res/android">
                """.trimIndent()
                )
            },
            bindables = listOf(
                Binding(
                    rawName = bindableName,
                    typeName = testClassName,
                    bindingType = BindingType.Variable
                ),
                Binding(
                    rawName = bindableNameWithUnderscoe,
                    typeName = testClassName,
                    bindingType = BindingType.Variable
                )
            ),
            bindings = listOf(
                Binding(
                    rawName = bindingName,
                    typeName = testClassName,
                    bindingType = BindingType.View
                ),
                Binding(
                    rawName = bindingFragmentRawName,
                    typeName = ClassName.get("android.widget", "fragment"),
                    bindingType = BindingType.View
                )
            )
        )
    }

    @Test
    fun `assert constructor method has binding information`() {
        defaultBindingClassGenerator.generate(testPackage, listOf(layoutBinding))
        assertTrue("Constructor arguments contain bindings") {
            generatedFileContents.contains(
                """  protected SimpleBinding(Object _bindingComponent, View _root, int _localFieldCount,
      Class timeDisplay) {"""
            )
        }
    }

    @Test
    fun `assert inflate methods are generated`() {
        defaultBindingClassGenerator.generate(testPackage, listOf(layoutBinding))
        assertTrue() {
            generatedFileContents.contains(
                """  @NonNull
  public static SimpleBinding inflate(LayoutInflater inflater, ViewGroup root,
      boolean attachToRoot) {"""
            )
        }

        assertTrue {
            generatedFileContents.contains(
                """  @NonNull
  public static SimpleBinding inflate(LayoutInflater inflater, ViewGroup root, boolean attachToRoot,
      Object component) {"""
            )
        }

        assertTrue {
            generatedFileContents.contains(
                """  @NonNull
  public static SimpleBinding inflate(LayoutInflater inflater) {"""
            )
        }
    }

    @Test
    fun `assert public binding fields are generated`() {
        defaultBindingClassGenerator.generate(testPackage, listOf(layoutBinding))
        assertTrue {
            generatedFileContents.contains(
                """  @NonNull
  public final Class timeDisplay;"""
            )
        }
        assertFalse("Invalid binding types are not considered") {
            generatedFileContents.contains(
                """  @NonNull
  public final fragment fragmentView;"""
            )
        }
        assertTrue {
            generatedFileContents.contains(
                """  @Bindable
  protected Class mVm;"""
            )
        }
    }

    @Test
    fun `assert bindable setters and getters are generated`() {
        defaultBindingClassGenerator.generate(testPackage, listOf(layoutBinding))
        assertTrue {
            generatedFileContents.contains(
                """  public abstract void setVm(Class var1);"""
            )
        }
        assertTrue {
            generatedFileContents.contains(
                """  @Nullable
  public Class getVm() {"""
            )
        }
        assertTrue {
            generatedFileContents.contains(
                """  public abstract void setVmTest(Class var1);"""
            )
        }
        assertTrue {
            generatedFileContents.contains(
                """  @Nullable
  public Class getVmTest() {"""
            )
        }
    }

    @Test
    fun `assert bind mehods are generated`() {
        defaultBindingClassGenerator.generate(testPackage, listOf(layoutBinding))
        assertTrue {
            generatedFileContents.contains(
                """  @NonNull
  public static SimpleBinding bind(View view) {"""
            )
        }
        assertTrue {
            generatedFileContents.contains(
                """  @NonNull
  public static SimpleBinding bind(View view, Object component) {"""
            )
        }
    }


    @Test
    fun `assert included layouts without corresponding layout file has empty binding generated`() {
        val includedLayoutName = "IncludedLayoutBinding"
        val calculatedLayouts = defaultBindingClassGenerator.calculateBindingsToGenerate(
            layoutBindings = listOf(
                LayoutBindingData(
                    layoutName = "RootBinding",
                    file = temporaryFolder.newFile("root_binding.xml").apply {
                        writeText(
                            """
                            <layout xmlns:android="http://schemas.android.com/apk/res/android">
                            """.trimIndent()
                        )
                    },
                    bindings = listOf(
                        Binding(
                            rawName = bindingName,
                            typeName = ClassName.get(testPackage, includedLayoutName),
                            bindingType = BindingType.IncludedLayout(
                                includedLayoutName,
                                layoutMissing = true
                            )
                        )
                    ),
                    bindables = emptyList()
                )
            )
        ).toList()

        assertEquals(2, calculatedLayouts.size)
        val includedBinding = calculatedLayouts.last()
        assertEquals(includedLayoutName, includedBinding.layoutName)
        assertEquals(0, includedBinding.bindables.size)
        assertEquals(0, includedBinding.bindings.size)
    }

    @Test
    fun `assert included layout with layout file do not get replaced with empty bindings`() {
        val includedLayoutName = "IncludedLayoutBinding"

        val bindings = listOf(
            Binding(
                rawName = bindingName,
                typeName = ClassName.bestGuess(className),
                bindingType = BindingType.View
            )
        )

        val calculatedLayouts = defaultBindingClassGenerator.calculateBindingsToGenerate(
            layoutBindings = listOf(
                LayoutBindingData(
                    layoutName = "RootBinding",
                    file = temporaryFolder.newFile("root_binding.xml").apply {
                        writeText(
                            """
                            <layout xmlns:android="http://schemas.android.com/apk/res/android">
                            """.trimIndent()
                        )
                    },
                    bindings = listOf(
                        Binding(
                            rawName = bindingName,
                            typeName = ClassName.get(testPackage, includedLayoutName),
                            bindingType = BindingType.IncludedLayout(includedLayoutName)
                        )
                    ),
                    bindables = emptyList()
                ),
                LayoutBindingData(
                    layoutName = includedLayoutName,
                    file = temporaryFolder.newFile("included_layout.xml").apply {
                        writeText(
                            """
                            <layout xmlns:android="http://schemas.android.com/apk/res/android">
                            """.trimIndent()
                        )
                    },
                    bindables = emptyList(),
                    bindings = bindings
                )
            )
        ).toList()

        assertEquals(2, calculatedLayouts.size)
        val includedBinding = calculatedLayouts.last()
        assertEquals(includedLayoutName, includedBinding.layoutName)
        assertEquals(bindings, includedBinding.bindings)
    }
}