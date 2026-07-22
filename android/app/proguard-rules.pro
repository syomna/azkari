-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Geolocator / Google Play Services
-keep class com.google.android.gms.location.** { *; }
-dontwarn com.google.android.gms.location.**

# just_audio
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# sqflite
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

# permission_handler
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# flutter_compass
-keep class com.example.flutter_compass.** { *; }
-dontwarn com.example.flutter_compass.**
