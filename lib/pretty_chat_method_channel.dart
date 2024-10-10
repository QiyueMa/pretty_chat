import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'pretty_chat_platform_interface.dart';

/// An implementation of [PrettyChatPlatform] that uses method channels.
class MethodChannelPrettyChat extends PrettyChatPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('pretty_chat');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
