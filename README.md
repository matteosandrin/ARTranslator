![](https://github.com/matteosandrin/ARTranslator/raw/master/Promotional/banner.png)

## ARTranslator

### Inspiration

As an international student, I wanted to create a tool that makes learning another language easier and more fun. This app combines the immediacy of pointing your phone with the convenience of instantly seeing the word you're looking for.

### What it does

This app is capable of recognising, naming and translating in real time the objects it is looking at. The target word is first extracted from the live camera feed and then translated to any language through an external API. Then, both the original (English) and translated words a are displayed in augmented reality, which allows them to "stick" to the object they identify.
<p align="center">
  <img width="200" src="https://github.com/matteosandrin/ARTranslator/raw/master/Promotional/screenshot_1.PNG" style="padding: 10px">
  <img width="200" src="https://github.com/matteosandrin/ARTranslator/raw/master/Promotional/screenshot_2.PNG" style="padding: 10px">
</p>

### How it's made
The app was entirely built in Swift. It is based heavily on the work of Github user [hanleywang](https://github.com/hanleyweng/CoreML-in-ARKit). Specifically, the image recognition part of this project was accomplished through the InceptionV3 machine learning model, which was integrated inside the iOS app via Apple's CoreML APIs. The translation component was carried out through the Google Cloud Translate APIs. Finally, the augmented reality component was possible thanks to Apple's newest ARKit framework.

## Usage

1: Install CocoaPods for dependency management (requires Xcode developer tools).

```
sudo gem install cocoapods
```
2: While in the repository's root directory, install dependencies.

```
pod install
```
