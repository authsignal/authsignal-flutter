# Add project specific ProGuard rules here.

# SLF4J - Suppress warnings for missing StaticLoggerBinder
-dontwarn org.slf4j.impl.StaticLoggerBinder
-dontwarn org.slf4j.**

# Keep Authsignal classes
-keep class com.authsignal.** { *; }

