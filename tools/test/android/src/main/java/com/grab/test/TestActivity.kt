package com.grab.test

import android.app.Activity
import android.os.Bundle

class TestActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    fun sum(a: Int, b: Int): Int {
        return a + b
    }
}