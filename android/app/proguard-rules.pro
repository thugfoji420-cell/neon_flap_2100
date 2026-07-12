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
-keep class com.google.android.gms.internal.ads.** { *; }
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.**
