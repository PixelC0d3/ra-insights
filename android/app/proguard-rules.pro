# R8 rules for the release build. The Flutter Gradle plugin already contributes
# the engine's own rules, so this file only covers what the plugins need.

# Keep source file and line numbers so Play Console stack traces stay readable
# after deobfuscation with the uploaded mapping file.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# flutter_secure_storage stores the RetroAchievements Web API key in
# EncryptedSharedPreferences. androidx.security resolves the Tink primitives by
# name at runtime, so stripping them breaks reading the key back.
-keep class androidx.security.crypto.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# Tink pulls in optional Error Prone / Checker Framework annotations that are
# not on the runtime classpath.
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
-dontwarn com.google.errorprone.annotations.**

# drift talks to SQLite through FFI (sqlite3_flutter_libs); the Java side is a
# thin loader that R8 must not rename.
-keep class com.tekartik.sqflite.** { *; }
-dontwarn org.slf4j.**
