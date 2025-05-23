package com.alem.edu

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.ObjectAnimator
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.animation.AnticipateInterpolator
import android.view.animation.DecelerateInterpolator
import androidx.appcompat.app.AppCompatActivity
import androidx.core.animation.doOnEnd
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.alem.edu.databinding.ActivitySplashBinding
import com.google.firebase.analytics.FirebaseAnalytics
import com.google.firebase.ktx.Firebase
import io.flutter.embedding.android.FlutterActivity
import kotlinx.coroutines.*
import java.util.*

@Suppress("DEPRECATION")
class SplashActivity : AppCompatActivity() {
    private lateinit var binding: ActivitySplashBinding
    private val activityScope = CoroutineScope(Dispatchers.Main)
    private var isReady = false
    private var isAnimationFinished = false

    override fun onCreate(savedInstanceState: Bundle?) {
        // Handle the splash screen transition
        val splashScreen = installSplashScreen()
        super.onCreate(savedInstanceState)

        // Set up an OnPreDrawListener to the root view
        splashScreen.setOnExitAnimationListener { splashScreenView ->
            val slideUp = ObjectAnimator.ofFloat(
                splashScreenView.view,
                View.TRANSLATION_Y,
                0f,
                -splashScreenView.view.height.toFloat()
            )
            slideUp.interpolator = AnticipateInterpolator(1.0f)
            slideUp.duration = 300L

            // Call SplashScreenView.remove at the end of your custom animation
            slideUp.doOnEnd {
                splashScreenView.remove()
                isAnimationFinished = true
                checkIfReady()
            }

            // Start your animation
            slideUp.start()
        }


        // Bind the view
        binding = ActivitySplashBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Set version info
        try {
            val pInfo = packageManager.getPackageInfo(packageName, 0)
            val versionName = pInfo.versionName
            binding.tvVersion.text = getString(R.string.version_format, versionName)
        } catch (e: Exception) {
            binding.tvVersion.visibility = View.GONE
        }

        // Initialize Firebase
        FirebaseAnalytics.getInstance(this)


        // Start loading data in the background
        activityScope.launch {
            // Simulate some loading time
            delay(1500)
            
            withContext(Dispatchers.Main) {
                isReady = true
                checkIfReady()
            }
        }
    }

    private fun checkIfReady() {
        if (isReady && isAnimationFinished) {
            navigateToMain()
        }
    }

    private fun navigateToMain() {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            
            // Add animation
            startActivity(intent)
            overridePendingTransition(android.R.anim.fade_in, android.R.anim.fade_out)
            
            // Finish the splash activity
            finish()
        } catch (e: Exception) {
            e.printStackTrace()
            // If MainActivity fails, try to start FlutterActivity directly
            try {
                val intent = FlutterActivity.createDefaultIntent(this)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                startActivity(intent)
                finish()
            } catch (e2: Exception) {
                e2.printStackTrace()
                finishAffinity()
            }
        }
    }

    override fun onStop() {
        activityScope.cancel()
        super.onStop()
    }

    override fun onBackPressed() {
        // Disable back button during splash screen
    }
}
