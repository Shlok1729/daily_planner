package com.example.daily_planner

import android.app.Activity
import android.os.Build
import android.os.Bundle
import android.widget.TextView

class FocusLockActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        try {
            val textView = TextView(this).apply {
                text = "🚫 App Blocked\n\nFocus mode is active.\nReturn to your productivity goals!"
                textSize = 24f
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                    textAlignment = TextView.TEXT_ALIGNMENT_CENTER
                }
                setPadding(40, 40, 40, 40)
            }
            setContentView(textView)

            // Auto close after 3 seconds
            textView.postDelayed({
                finish()
            }, 3000)
        } catch (e: Exception) {
            android.util.Log.e("FocusLockActivity", "Error: ${e.message}")
            finish()
        }
    }
}