// import 'package:flutter_test/flutter_test.dart';
// import 'package:media_picker_plus/media_picker_plus.dart';
// import 'package:media_picker_plus/media_picker_plus_platform_interface.dart';
// import 'package:media_picker_plus/media_picker_plus_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// class MockMediaPickerPlusPlatform
//     with MockPlatformInterfaceMixin
//     implements MediaPickerPlusPlatform {

//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }

// void main() {
//   final MediaPickerPlusPlatform initialPlatform = MediaPickerPlusPlatform.instance;

//   test('$MethodChannelMediaPickerPlus is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelMediaPickerPlus>());
//   });

//   test('getPlatformVersion', () async {
//     MediaPickerPlus mediaPickerPlusPlugin = MediaPickerPlus();
//     MockMediaPickerPlusPlatform fakePlatform = MockMediaPickerPlusPlatform();
//     MediaPickerPlusPlatform.instance = fakePlatform;

//     expect(await mediaPickerPlusPlugin.getPlatformVersion(), '42');
//   });
// }
