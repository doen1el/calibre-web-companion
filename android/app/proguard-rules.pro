-keep class com.vocsy.epub_viewer.** { *; }

-keep class com.fasterxml.jackson.** { *; }
-keepnames class com.fasterxml.jackson.** { *; }

-dontwarn java.beans.**
-dontwarn javax.xml.**
-dontwarn org.w3c.dom.bootstrap.**

-keep class com.folioreader.** { *; }
-keep interface com.folioreader.** { *; }

-dontwarn org.joda.convert.**
-dontwarn org.joda.time.**

-keep class org.greenrobot.eventbus.** { *; }
-keepclassmembers class ** {
    @org.greenrobot.eventbus.Subscribe <methods>;
}
-keep enum org.greenrobot.eventbus.ThreadMode { *; }

-keep class retrofit2.** { *; }
-dontwarn retrofit2.**

-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

-dontwarn com.google.android.play.**

-keep class org.readium.** { *; }
-keepclassmembers class org.readium.** {
    public <init>();
}

-keep class org.nanohttpd.** { *; }
-keepclassmembers class org.nanohttpd.** {
    public <init>();
}