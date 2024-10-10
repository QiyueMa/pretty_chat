#include "include/pretty_chat/pretty_chat_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "pretty_chat_plugin.h"

void PrettyChatPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  pretty_chat::PrettyChatPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
