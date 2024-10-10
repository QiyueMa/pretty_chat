import 'pretty_chat_platform_interface.dart';

export 'chat.dart';

class PrettyChat {
  Future<String?> getPlatformVersion() {
    return PrettyChatPlatform.instance.getPlatformVersion();
  }
}
