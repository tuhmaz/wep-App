package com.alem.edu

import android.app.Application
import android.content.Context
import android.os.StrictMode
import com.google.firebase.FirebaseApp
import com.google.firebase.analytics.FirebaseAnalytics
import com.google.firebase.analytics.ktx.analytics
import com.google.firebase.ktx.Firebase

class AlemEduApplication : Application() {
    private lateinit var firebaseAnalytics: FirebaseAnalytics

    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        // Initialize MultiDex if needed
        // MultiDex.install(this)
    }


    override fun onCreate() {
        super.onCreate()
        
        try {
            // Initialize Firebase only if not already initialized
            if (FirebaseApp.getApps(this).isEmpty()) {
                FirebaseApp.initializeApp(this)
            }
            firebaseAnalytics = Firebase.analytics
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        // Enable strict mode in debug builds
        if (BuildConfig.DEBUG) {
            try {
                StrictMode.setThreadPolicy(
                    StrictMode.ThreadPolicy.Builder()
                        .detectAll()
                        .penaltyLog()
                        .build()
                )
                
                StrictMode.setVmPolicy(
                    StrictMode.VmPolicy.Builder()
                        .detectLeakedSqlLiteObjects()
                        .detectLeakedClosableObjects()
                        .penaltyLog()
                        .build()
                )
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        
        // Initialize other app-wide components here
        initializeApp()
    }
    
    private fun initializeApp() {
        // Initialize any app-wide components here
        // Example: Crashlytics, Analytics, WorkManager, etc.
        
        // Enable Firebase Performance Monitoring
        // Firebase.performance.isPerformanceCollectionEnabled = true
        
        // Enable Firebase Crashlytics
        // FirebaseCrashlytics.getInstance().setCrashlyticsCollectionEnabled(true)
    }
}
