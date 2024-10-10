import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'pretty_chat_method_channel.dart';

abstract class PrettyChatPlatform extends PlatformInterface {
  /// Constructs a PrettyChatPlatform.
  PrettyChatPlatform() : super(token: _token);

  static final Object _token = Object();

  static PrettyChatPlatform _instance = MethodChannelPrettyChat();

  /// The default instance of [PrettyChatPlatform] to use.
  ///
  /// Defaults to [MethodChannelPrettyChat].
  static PrettyChatPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PrettyChatPlatform] when
  /// they register themselves.
  static set instance(PrettyChatPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
