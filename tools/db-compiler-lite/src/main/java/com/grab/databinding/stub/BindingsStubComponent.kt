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

import com.grab.databinding.stub.binding.generator.BindingClassGenerator
import com.grab.databinding.stub.binding.BindingClassModule
import com.grab.databinding.stub.binding.parser.BindingsParserModule
import com.grab.databinding.stub.binding.parser.LayoutBindingsParser
import com.grab.databinding.stub.rclass.generator.ResToRClassGenerator
import com.grab.databinding.stub.rclass.di.ResToRClassModule
import com.grab.databinding.stub.brclass.BrClassGenerator
import com.grab.databinding.stub.brclass.BrClassModule
import com.grab.databinding.stub.common.CLASS_INFO
import com.grab.databinding.stub.common.LAYOUT_FILES
import com.grab.databinding.stub.common.RES_FILES
import com.grab.databinding.stub.common.OUTPUT
import com.grab.databinding.stub.common.PACKAGE_NAME
import com.grab.databinding.stub.common.R_TXT_ZIP
import com.grab.databinding.stub.rclass.generator.RClassGenerator
import com.grab.databinding.stub.rclass.generator.RClassModule
import dagger.BindsInstance
import dagger.Component
import java.io.File
import javax.inject.Named
import javax.inject.Singleton

@Singleton
@Component(
    modules = [
        RClassModule::class,
        BindingClassModule::class,
        BrClassModule::class,
        BindingsParserModule::class,
        ResToRClassModule::class
    ]
)
interface BindingsStubComponent {
    fun layoutBindingsParser(): LayoutBindingsParser
    fun resToRClassGenerator(): ResToRClassGenerator
    fun bindingClassGenerator(): BindingClassGenerator
    fun brClassGenerator(): BrClassGenerator

    @Component.Factory
    interface Factory {
        /**
         * Construct the [BindingsStubComponent] injector.
         *
         * @param outputDir The output dir root where the files should be generated
         * @param packageName The package name of the target for which stubs are to be generated
         * @param
         */
        fun create(
            @BindsInstance @Named(OUTPUT) outputDir: File?,
            @BindsInstance @Named(PACKAGE_NAME) packageName: String,
            @BindsInstance @Named(LAYOUT_FILES) layoutFiles: List<File>,
            @BindsInstance @Named(RES_FILES) resFiles: List<File>,
            @BindsInstance @Named(CLASS_INFO) classInfoZip: File,
            @BindsInstance @Named(R_TXT_ZIP) rTxtZip: File
        ): BindingsStubComponent
    }
}