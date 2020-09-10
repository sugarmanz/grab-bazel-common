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

package com.grab.pax.binding.processor

import com.tschuchort.compiletesting.KotlinCompilation
import com.tschuchort.compiletesting.SourceFile
import org.junit.Test
import kotlin.test.assertTrue

class GeneratedMethodsTest {

    private fun compile(sourceFile: SourceFile): KotlinCompilation.Result {
        return KotlinCompilation().apply {
            sources = listOf(sourceFile)
            annotationProcessors = listOf(BindingAdapterProcessor())
            inheritClassPath = true
            messageOutputStream = System.out
        }.compile()
    }

    @Test
    fun `assert generated Java proxies have correct binding adapter annotations`() {
        val bindingAdapterSource = SourceFile.kotlin(
            "Test.kt", """
            package test
            import androidx.databinding.BindingAdapter
            @BindingAdapter("test", requireAll = false)
            fun updateNode(value: Int) {
                println(value)
            }
        """.trimIndent()
        )
        val result = compile(bindingAdapterSource)
        assertTrue() {
            result.exitCode == KotlinCompilation.ExitCode.OK
        }
        val generated =
            result.generatedFiles.first { it.name.contains("test_Binding_Adapter_Stub") }.readText()
        assertTrue("Generated proxy has expected annotations") {
            generated == """
                package test;

                import androidx.databinding.BindingAdapter;

                public class test_Binding_Adapter_Stub {
                  @BindingAdapter(
                      value = "test",
                      requireAll = false
                  )
                  public static void updateNode(int value) {
                    TestKt.updateNode(value);
                  }
                }

            """.trimIndent()
        }
    }


    @Test
    fun `assert generate Java proxies have correct inverse binding adapter annotations`() {
        val bindingAdapterSource = SourceFile.kotlin(
            "Test.kt", """
            package test
            import androidx.databinding.InverseBindingAdapter
            @InverseBindingAdapter(attribute = "test")
            fun updateNode(value: Int) : Int {
                return 0
            }
        """.trimIndent()
        )
        val result = compile(bindingAdapterSource)
        assertTrue {
            result.exitCode == KotlinCompilation.ExitCode.OK
        }
        val generated =
            result.generatedFiles.first { it.name.contains("test_Binding_Adapter_Stub") }.readText()
        assertTrue("Generated proxy has expected annotations") {
            generated == """
                package test;

                import androidx.databinding.InverseBindingAdapter;

                public class test_Binding_Adapter_Stub {
                  @InverseBindingAdapter(
                      attribute = "test"
                  )
                  public static int updateNode(int value) {
                    return TestKt.updateNode(value);
                  }
                }

            """.trimIndent()
        }
    }
}