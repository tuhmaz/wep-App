package com.alem.edu

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.google.firebase.FirebaseApp
import com.google.firebase.analytics.FirebaseAnalytics
import com.google.firebase.analytics.ktx.analytics
import com.google.firebase.ktx.Firebase

class MainActivity : FlutterActivity() {
    private lateinit var firebaseAnalytics: FirebaseAnalytics

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        try {
            // Initialize Firebase only if not already initialized
            if (FirebaseApp.getApps(this).isEmpty()) {
                FirebaseApp.initializeApp(this)
            }
            firebaseAnalytics = Firebase.analytics
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable full screen mode
        window.setFlags(
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
        )
        
        // Keep screen on for certain activities if needed
        // window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        
        super.onCreate(savedInstanceState)
    }

    override fun onResume() {
        super.onResume()
        // Track screen view in analytics
        firebaseAnalytics.setCurrentScreen(this, "MainActivity", null)
    }
}
