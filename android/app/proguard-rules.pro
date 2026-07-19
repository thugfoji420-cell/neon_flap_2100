# Google Mobile Ads (play-services-ads) initializes AndroidX WorkManager at
# startup via androidx.startup. WorkManager uses a Room database whose
# implementation class (WorkDatabase_Impl) is generated at build time; without
# these keep rules R8 strips it and the app crashes on launch with
# "Failed to create an instance of androidx.work.impl.WorkDatabase".
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.Worker
-keep class androidx.work.impl.** { *; }

# AndroidX Room generated database implementation classes.
-keep class * extends androidx.room.RoomDatabase
-keep class androidx.room.** { *; }

# Google Mobile Ads SDK internals.
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.ads.internal.** { *; }
-keep class com.google.android.gms.common.util.** { *; }
-keep class com.google.android.gms.internal.ads.** { *; }
-keep class com.google.android.gms.ads.admanager.** { *; }
-keep class com.google.android.gms.ads.mediation.** { *; }
-keep class com.google.android.gms.ads.rewarded.** { *; }
-dontwarn com.google.android.gms.**

# Firebase SDK keep rules - required for release builds with minification enabled.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.firebase.provider.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.tasks.**

# Flutter embedding and generated plugin registrants.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Keep native methods that are called from Dart via FFI or platform channels.
-keepclasseswithmembernames class * {
    native <methods>;
}

# Play Core library classes referenced by Flutter embedding for deferred components.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
