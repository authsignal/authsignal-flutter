# Keep slf4j - used by ktor HTTP client
-dontwarn org.slf4j.**
-keep class org.slf4j.** { *; }

# Keep ktor classes
-dontwarn io.ktor.**
-keep class io.ktor.** { *; }

# Keep kotlinx serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasseswithmembers class kotlinx.serialization.json.** {
    kotlinx.serialization.KSerializer serializer(...);
}

-keep,includedescriptorclasses class com.authsignal.**$$serializer { *; }
-keepclassmembers class com.authsignal.** {
    *** Companion;
}
-keepclasseswithmembers class com.authsignal.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Keep Authsignal SDK classes
-keep class com.authsignal.** { *; }

