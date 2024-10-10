import 'package:flutter_test/flutter_test.dart';
import 'package:pretty_chat/pretty_chat.dart';
import 'package:pretty_chat/pretty_chat_platform_interface.dart';
import 'package:pretty_chat/pretty_chat_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPrettyChatPlatform
    with MockPlatformInterfaceMixin
    implements PrettyChatPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final PrettyChatPlatform initialPlatform = PrettyChatPlatform.instance;

  test('$MethodChannelPrettyChat is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPrettyChat>());
  });

  test('getPlatformVersion', () async {
    PrettyChat prettyChatPlugin = PrettyChat();
    MockPrettyChatPlatform fakePlatform = MockPrettyChatPlatform();
    PrettyChatPlatform.instance = fakePlatform;

    expect(await prettyChatPlugin.getPlatformVersion(), '42');
  });
}
