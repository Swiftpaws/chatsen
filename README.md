<p align="middle">
<img align="middle" height="96" src="assets/ayyybubu/forsenShrimp/original.png">
<p>
<h1 align="middle">Chatsen</h1>
<h2>!Attention! Heavy vibecoding</h2>
<p>Im just doing this because of lack of alternatives right now, not intended for distribution</p>


The Chatsen logo was graciously made by @ayyybubu! You can find him on [Twitter](https://twitter.com/ayyybubu) or [Twitch](https://twitch.tv/ayyybubu)

  
<!-- # iOS Sideloading Guide
- Install AltStore on your device https://altstore.io/
- Download the .ipa file available on the [release page](https://github.com/Chatsen/chatsen/releases)
- Open the .ipa file with AltStore on your iPhone

Note: the .ipa file is not signed but will be signed automatically with AltStore on your device. -->

# Build instructions
To build Chatsen, all you should need is the Flutter SDK on the **master** branch and it's required dependencies for your platform (Android Studio for Android and Xcode for iOS).  
Running the following commands should allow you to build the application successfully:

```bash
flutter create .
rm -rf test

# Android
sed -i '/<\/manifest>/i \ \ \ \ <uses-sdk tools:overrideLibrary="io.flutter.plugins.webviewflutter"/>' ./android/app/src/main/AndroidManifest.xml
sed -i '/.*package=".*".*/i \ \ \ \ xmlns:tools="http://schemas.android.com/tools"' ./android/app/src/main/AndroidManifest.xml
sed -i '/.*package=".*".*/a \ \ \ <uses-permission android:name="android.permission.INTERNET"/>' ./android/app/src/main/AndroidManifest.xml
sed -i '/.*release {.*/a \ \ \ \ \ \ \ \ \ \ \ \ shrinkResources false\n\ \ \ \ \ \ \ \ \ \ \ \ minifyEnabled false' ./android/app/build.gradle
flutter pub run flutter_launcher_icons:main
flutter build apk

# iOS
flutter pub run flutter_launcher_icons:main
flutter build ios --no-codesign
```

You may also check the Github Actions file [here](https://github.com/chatsen/chatsen/blob/master/.github/workflows/main.yml) for more details.

# Licensing
Chatsen is distributed under the AGPLv3 licence. A copy may be found in the LICENCE file in that repository. All the dependencies remain under their original licenses.

# Usage
This project and it's releases are provided as-is, no support is provided. Use at your own discretion.

# Privacy Policy
Chatsen does not collect any personal or identifying information whatsoever. There are no servers, services or backend running related to the project either.  
Since Chatsen interfaces with Twitch however, you are subject to their Privacy Policy available at https://www.twitch.tv/p/en/legal/privacy-notice/

# Contributions
Chatsen currently does *not* take any pull requests or contributions. When this may change in the future, this notice will be updated and PR guidelines will be defined.