## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

## Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

## Google Play Core (required for Flutter deferred components)
-dontwarn com.google.android.play.core.**

## Keep annotations
-keepattributes *Annotation*

## Prevent stripping of native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
