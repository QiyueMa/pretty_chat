
import 'pretty_chat_platform_interface.dart';

class PrettyChat {
  Future<String?> getPlatformVersion() {
    return PrettyChatPlatform.instance.getPlatformVersion();
  }
}
