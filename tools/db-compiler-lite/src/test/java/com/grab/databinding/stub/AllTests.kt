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

import com.grab.databinding.stub.binding.DefaultLayoutBindingsParserTest
import com.grab.databinding.stub.binding.generator.DefaultBindingClassGeneratorTest
import com.grab.databinding.stub.binding.store.CachingBindingClassJsonParserTest
import com.grab.databinding.stub.brclass.DefaultBrClassGeneratorTest
import com.grab.databinding.stub.rclass.parser.DefaultRTxtParserTest
import com.grab.databinding.stub.rclass.parser.ResToRValueParserTest
import com.grab.databinding.stub.rclass.parser.ResToRFileIDParserTest
import com.grab.databinding.stub.rclass.parser.ResToRStyleableValueParserTest
import com.grab.databinding.stub.rclass.parser.ResToRDepsParserTest
import com.grab.databinding.stub.rclass.xml.DefaultXmlParserTest
import com.grab.databinding.stub.rclass.xml.ArrayParserTest
import com.grab.databinding.stub.rclass.xml.StyleParserTest
import com.grab.databinding.stub.rclass.xml.IDParserTest
import com.grab.databinding.stub.rclass.xml.DeclareStyleableParserTest
import org.junit.runner.RunWith
import org.junit.runners.Suite

@RunWith(Suite::class)
@Suite.SuiteClasses(
    value = [
        DefaultLayoutBindingsParserTest::class,
        DefaultBindingClassGeneratorTest::class,
        DefaultRTxtParserTest::class,
        DefaultBrClassGeneratorTest::class,
        CachingBindingClassJsonParserTest::class,
        ResToRValueParserTest::class,
        ResToRFileIDParserTest::class,
        DefaultXmlParserTest::class,
        ArrayParserTest::class,
        StyleParserTest::class,
        DeclareStyleableParserTest::class,
        ResToRStyleableValueParserTest::class,
        ResToRDepsParserTest::class
    ]
)
class AllTests