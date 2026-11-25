# Keep Firebase & Local Notifications
-keep class com.google.firebase.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Keep GetX / Reflection
-keepclassmembers class * {
    @ 用法 ...
}