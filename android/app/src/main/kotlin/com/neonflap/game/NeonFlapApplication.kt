package com.neonflap.game

import android.app.Application
import com.facebook.FacebookSdk
import com.facebook.appevents.AppEventsLogger

class NeonFlapApplication : Application() {
  override fun onCreate() {
    super.onCreate()
    FacebookSdk.sdkInitialize(this)
    AppEventsLogger.activateApp(this)
  }
}
