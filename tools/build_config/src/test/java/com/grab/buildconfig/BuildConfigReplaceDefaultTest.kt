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

package com.grab.buildconfig

import com.grab.buildconfig.sample.BuildConfig
import org.junit.Test
import kotlin.test.assertEquals

const val VERSION_FROM_CONFIG = "1.2.3"

class BuildConfigReplaceDefaultTest {

    @Test
    fun `assert VERSION_NAME should not be replaced by default value`() {
        assertEquals(
            VERSION_FROM_CONFIG,
            BuildConfig.VERSION_NAME,
            "Version name is replaced by default value"
        )
    }
}