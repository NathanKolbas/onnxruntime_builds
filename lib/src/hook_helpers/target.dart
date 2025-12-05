/// This is copied from Cargokit (which is the official way to use it currently)
/// Details: https://fzyzcjy.github.io/flutter_rust_bridge/manual/integrate/builtin

import 'dart:io';

import 'package:collection/collection.dart';

import 'util.dart';

class Target {
  Target({
    required this.name,
    this.flutter,
    this.android,
    this.androidMinSdkVersion,
    this.iosMinSdkVersion,
    this.darwinPlatform,
    this.darwinArch,
  });

  static final all = [
    Target(
      name: 'armeabi-v7a-linux-android',
      flutter: 'android-arm',
      android: 'armeabi-v7a',
      androidMinSdkVersion: 28,
    ),
    Target(
      name: 'arm64-v8a-linux-android',
      flutter: 'android-arm64',
      android: 'arm64-v8a',
      androidMinSdkVersion: 28,
    ),
    Target(
      name: 'x86-linux-android',
      flutter: 'android-x86',
      android: 'x86',
      androidMinSdkVersion: 28,
    ),
    Target(
      name: 'x86_64-linux-android',
      flutter: 'android-x64',
      android: 'x86_64',
      androidMinSdkVersion: 28,
    ),
    Target(
      name: 'x86_64-windows-msvc',
      flutter: 'windows-x64',
    ),
    Target(
      name: 'arm64-windows-msvc',
      flutter: 'windows-arm64',
    ),
    Target(
      name: 'x86_64-linux-gnu',
      flutter: 'linux-x64',
    ),
    Target(
      name: 'arm64-linux-gnu',
      flutter: 'linux-arm64',
    ),
    Target(
      name: 'x86_64-apple-darwin',
      darwinPlatform: 'macosx',
      darwinArch: 'x86_64',
    ),
    Target(
      name: 'arm64-apple-darwin',
      darwinPlatform: 'macosx',
      darwinArch: 'arm64',
    ),
    Target(
      name: 'arm64-apple-ios',
      darwinPlatform: 'iphoneos',
      darwinArch: 'arm64',
      iosMinSdkVersion: 15,
    ),
    Target(
      name: 'arm64-apple-ios-sim',
      darwinPlatform: 'iphonesimulator',
      darwinArch: 'arm64',
      iosMinSdkVersion: 15,
    ),
    Target(
      name: 'x86_64-apple-ios-sim',
      darwinPlatform: 'iphonesimulator',
      darwinArch: 'x86_64',
      iosMinSdkVersion: 15,
    ),
  ];

  static Target? forFlutterName(String flutterName) {
    return all.firstWhereOrNull((element) => element.flutter == flutterName);
  }

  static Target? forDarwin({
    required String platformName,
    required String darwinAarch,
  }) {
    return all.firstWhereOrNull((element) =>
        element.darwinPlatform == platformName &&
        element.darwinArch == darwinAarch);
  }

  static Target? forName(String name) {
    return all.firstWhereOrNull((element) => element.name == name);
  }

  static List<Target> androidTargets() {
    return all
        .where((element) => element.android != null)
        .toList(growable: false);
  }

  /// Returns buildable targets on current host platform ignoring Android targets.
  static List<Target> buildableTargets() {
    if (Platform.isLinux) {
      // Right now we don't support cross-compiling on Linux. So we just return
      // the host target.
      final arch = runCommand('arch', []).stdout as String;
      if (arch.trim() == 'aarch64') {
        return [Target.forName('arm64-linux-gnu')!];
      } else {
        return [Target.forName('x86_64-linux-gnu')!];
      }
    }
    return all.where((target) {
      if (Platform.isWindows) {
        return target.name.contains('-windows-');
      } else if (Platform.isMacOS) {
        return target.darwinPlatform != null;
      }
      return false;
    }).toList(growable: false);
  }

  @override
  String toString() {
    return name;
  }

  final String name;
  final String? flutter;
  final String? android;
  final int? androidMinSdkVersion;
  final int? iosMinSdkVersion;
  final String? darwinPlatform;
  final String? darwinArch;

  bool get isWindows => name.contains('-windows-');
  bool get isLinux => name.contains('-linux-');
  bool get isMacOS => darwinPlatform == 'macosx';
  bool get isAndroid => android != null;
  bool get isIOS => darwinPlatform == 'iphoneos' || darwinPlatform == 'iphonesimulator';
}
