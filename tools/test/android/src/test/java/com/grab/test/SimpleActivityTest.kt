package com.grab.test

import org.junit.Assert.assertEquals
import org.junit.Test

class SimpleActivityTest {

    @Test
    fun `assert sum invocation works`() {
        val activity = TestActivity()
        assertEquals(4, activity.sum(2, 2))
    }

    @Test
    fun `assert framework methods return default values`() {
        val activity = TestActivity()
        assertEquals(0, activity.getColor(0))
        assertEquals(null, activity.getString(0))
        assertEquals(null, activity.packageManager)
        assertEquals(null, activity.theme)
        assertEquals(null, activity.createAttributionContext("any"))
        assertEquals(false, activity.isDestroyed)
    }

    @Test
    fun `assert resource values`() {
        val activity = TestActivity()
        assertEquals(activity.material_res, com.google.android.material.R.color.material_blue_grey_950)
    }
}