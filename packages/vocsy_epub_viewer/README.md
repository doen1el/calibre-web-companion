# Vocsy Epub Viewer [![pub package](https://img.shields.io/pub/v/vocsy_epub_viewer.svg)](https://pub.dartlang.org/packages/vocsy_epub_viewer)

originally a fork of [epub_kitty](https://github.com/451518849/epub_kitty) with few more features. i
made this out of epub_kitty because the author was inactive(he isn't merging PRs or attending to
issues) and i started having alot of issues with the plugin

vocsy_epub_viewer is an epub ebook reader that encapsulates
the [folioreader](https://folioreader.github.io/FolioReaderKit/) framework. It supports iOS and
android.

## Features

| Name | Android | iOS |
|------|-------|------|
| Reading Time Left / Pages left | ✅ | ✅ |
| Last Read Locator | ✅ | ✅ |
| Distraction Free Reading | ✅ | ❌ |
| Load E-Pub from Asset | ✅ | ✅ |
| Copy and Share Text  | ✅ | ✅ |
| Highlight Text  | ✅ | ✅ |
| Multiple Theme [Light / Dark] | ✅ | ❌ |
| Support Multiple Device Language | ✅ | ✅ |
| Change FontStyle | ✅ | ❌ |
| Android 13 Supported | ✅ | ❌ |

## ScreenShots

+ Light
<a href="#screenshots">
  <img src="https://raw.githubusercontent.com/kaushikgodhani/vocsy_epub_viewer/main/screenshots/S1.jpg" width="200px">
</a>&nbsp;&nbsp;
<a href="#screenshots">
  <img src="https://raw.githubusercontent.com/kaushikgodhani/vocsy_epub_viewer/main/screenshots/S3.jpg" width="200px">
</a>&nbsp;&nbsp;
<a href="#screenshots">
  <img src="https://raw.githubusercontent.com/kaushikgodhani/vocsy_epub_viewer/main/screenshots/S11.jpg" width="200px">
</a>&nbsp;&nbsp;
<a href="#screenshots">
  <img src="https://raw.githubusercontent.com/kaushikgodhani/vocsy_epub_viewer/main/screenshots/S4.jpg" width="200px">
</a>&nbsp;&nbsp;
<a href="#screenshots">
  <img src="https://raw.githubusercontent.com/kaushikgodhani/vocsy_epub_viewer/main/screenshots/S5.jpg" width="200px">
</a>&nbsp;&nbsp;
<a href="#screenshots">
  <img src="https://raw.githubusercontent.com/kaushikgodhani/vocsy_epub_viewer/main/screenshots/S6.jpg" width="200px">
</a>&nbsp;&nbsp;

+ Dark


<a href="#screenshots">
  <img src="https://raw.githubusercontent.com/kaushikgodhani/vocsy_epub_viewer/main/screenshots/S2.jpg" width="200px">
</a>&nbsp;&nbsp;
<a href="#screenshots">
  <img src="https://raw.githubusercontent.com/kaushikgodhani/vocsy_epub_viewer/main/screenshots/S7.jpg" width="200px">
</a>&nbsp;&nbsp;
<a href="#screenshots">
  <img src="https://raw.githubusercontent.com/kaushikgodhani/vocsy_epub_viewer/main/screenshots/S8.jpg" width="200px">
</a>&nbsp;&nbsp;
<a href="#screenshots">
  <img src="https://raw.githubusercontent.com/kaushikgodhani/vocsy_epub_viewer/main/screenshots/S9.jpg" width="200px">
</a>&nbsp;&nbsp;
<a href="#screenshots">
  <img src="https://raw.githubusercontent.com/kaushikgodhani/vocsy_epub_viewer/main/screenshots/S10.jpg" width="200px">
</a>&nbsp;&nbsp;

## Install

This plugin requires `Swift` to work on iOS. Also, the minimum deployment target is 9.0

```
platform :ios, '9.0'
```

Import into pubspec.yaml

```
dependencies:
  vocsy_epub_viewer: latest_version
```

**NOTE** Please add this to the release build type in your app build.gradle to avoid crashes on android
release builds

```
minifyEnabled false
shrinkResources false
```

**NOTE** Add These Lines In manifest

<a href="#screenshots">
  <img src="https://raw.githubusercontent.com/kaushikgodhani/vocsy_epub_viewer/main/screenshots/img.png" >
</a>&nbsp;&nbsp;

+ 1 
```java
    <uses-permission android:name="android.permission.INTERNET" />
```    
+ 2 
 ```java  
    xmlns:tools="http://schemas.android.com/tools"
 ```
+ 3 
 ```java  
    android:usesCleartextTraffic="true"
    android:requestLegacyExternalStorage="true"
    android:networkSecurityConfig="@xml/network_security_config"
```
+ 4 
 ```java  
    android:exported="true"
```

**NOTE** `android` -> `app` -> `src` -> `main` -> `res` -> `xml` Inside xml Folder create xml file [network_security_config.xml](https://github.com/kaushikgodhani/vocsy_epub_viewer/tree/main/example/android/app/src/main/res/xml)
## Usage

```dart
VocsyEpub.setConfig(
           themeColor: Theme.of(context).primaryColor,
           identifier: "iosBook",
           scrollDirection: EpubScrollDirection.ALLDIRECTIONS,
           allowSharing: true,
           enableTts: true,
           nightMode: true,
       );

/**
 * @bookPath
 * @lastLocation (optional and only android)
 */
VocsyEpub.open(
          'bookPath',
           lastLocation: EpubLocator.fromJson({
	   "bookId": "2239",
	   "href": "/OEBPS/ch06.xhtml",
	   "created": 1539934158390,
	   "locations": {
		"cfi": "epubcfi(/0!/4/4[simple_book]/2/2/6)"
	          }
	    }), // first page will open up if the value is null
        );

// Get locator which you can save in your database

VocsyEpub.locatorStream.listen((locator) {
	print('LOCATOR: ${EpubLocator.fromJson(jsonDecode(locator))}');
	// convert locator from string to json and save to your database to be retrieved later
});

```
You can also load epub from your assets using `EpubViewer.openAsset()`

```dart
await VocsyEpub.openAsset('assets/3.epub',
lastLocation: EpubLocator.fromJson({
	"bookId": "2239",
	"href": "/OEBPS/ch06.xhtml",
	"created": 1539934158390,
	"locations": {
	"cfi": "epubcfi(/0!/4/4[simple_book]/2/2/6)"
	  }
	}), // first page will open up if the value is null
   );

// Get locator which you can save in your database

VocsyEpub.locatorStream.listen((locator) {
	print('LOCATOR: ${EpubLocator.fromJson(jsonDecode(locator))}');
	// convert locator from string to json and save to your database to be retrieved later
});

 ```
Check the [Example](https://github.com/kaushikgodhani/vocsy_epub_viewer/blob/main/example/lib/main.dart) for implementation

## Issues

If you encounter any problems feel free to open an issue. If you feel the library is missing a
feature, please raise a ticket on Github and I'll look into it. Pull request are also welcome.

For help getting started with Flutter, view the online
[documentation](https://flutter.io/).

For help on editing plugin code, view
the [documentation](https://flutter.io/platform-plugins/#edit-code).
	
