# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keepclasseswithmembernames class com.google.android.gms.** { *; }
-keepclasseswithmembernames class com.google.firebase.** { *; }

# Hive
-keep class com.example.hello.hive.** { *; }
-keep @com.hive.FlutterHive class * { *; }
-keep class * extends com.hive.HiveObject { *; }

# Socket.io
-keep class io.socket.** { *; }
-keep interface io.socket.** { *; }

# Google Sign In
-keep class com.google.android.gms.auth.api.signin.** { *; }

# Play Store classes (optional features - don't fail if missing)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# OkHttp classes (optional)
-dontwarn com.squareup.okhttp.**
-keep class com.squareup.okhttp.** { *; }

# Java reflection
-dontwarn java.lang.reflect.AnnotatedType
-keep class java.lang.reflect.AnnotatedType { *; }

# R8/ProGuard settings
-optimizationpasses 5
-verbose
-dontskipnonpubliclibraryclasses
-keepattributes *Annotation*
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes Signature
-keepattributes SourceFile
-keepattributes LineNumberTable
-keepattributes LocalVariableTable
-keepattributes LocalVariableTypeTable
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations
-keepattributes AnnotationDefault

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep classes used via reflection
-keepclasseswithmembers class * {
    *** *(...);
}

# Remove logging
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
