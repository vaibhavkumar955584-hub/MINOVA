# Proguard & R8 rules for MineSafe (MINOVA)

# ML Kit Text Recognition (suppress optional non-latin language builders warnings)
-dontwarn com.google.mlkit.vision.text.**
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }

# Flutter & Plugins
-keepattributes *Annotation*
-dontwarn androidx.work.**
-dontwarn com.google.firebase.**
