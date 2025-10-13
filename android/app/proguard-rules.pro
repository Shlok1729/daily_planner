# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# ================================
# FLUTTER SPECIFIC RULES
# ================================

# Keep Flutter-specific classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Firebase classes (if needed)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Facebook SDK classes
-keep class com.facebook.** { *; }

# FIXED: Keep app blocker specific classes with correct package name
-keep class com.example.daily_planner.** { *; }

# Keep method channel related classes
-keepclassmembers class ** {
    @io.flutter.plugin.common.MethodCall *;
}

# ================================
# ANDROIDX CORE RULES
# ================================

# Keep androidx.core classes (CRITICAL FOR FIXING UNRESOLVED REFERENCE)
-keep class androidx.core.** { *; }
-keep class androidx.appcompat.** { *; }
-keep class androidx.annotation.** { *; }
-keep class androidx.activity.** { *; }
-keep class androidx.fragment.** { *; }

# ================================
# GENERAL ANDROID RULES
# ================================

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable implementations
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ================================
# OPTIMIZATION RULES
# ================================

# Enable optimization
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Remove debug prints
-assumenosideeffects class java.io.PrintStream {
    public void println(%);
    public void println(**);
}

# ================================
# THIRD PARTY LIBRARIES
# ================================

# OkHttp3
-dontwarn okhttp3.**
-dontwarn okio.**

# Retrofit2
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }

# Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Remove warnings
-dontwarn java.lang.invoke.**
-dontwarn **$$serializer
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-dontwarn retrofit2.KotlinExtensions
-dontwarn retrofit2.KotlinExtensions$*