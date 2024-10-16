import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:bubble/bubble.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:pretty_chat/chat_connect.dart';
import 'package:provider/provider.dart';

String randomString() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}

class ChatMainPage extends StatefulWidget {
  final Widget svg;
  final String assistantId;
  const ChatMainPage({
    super.key,
    required this.svg,
    required this.assistantId,
  });

  @override
  State<ChatMainPage> createState() => ChatMainPageState();
}

class ChatMainPageState extends State<ChatMainPage> {
  late ChatConnect chatConnect;
  String text1 = "Hi. how can I help you?";
  String text2 =
      "I'm Aimy, your personal chatbot assistant. With access to various data and a wealth of FAQ knowledge, I'm ready to answer your questions. I can also assist you with managing your fleet!";

  final _user = const types.User(
    id: '82091008-a484-4a89-ae75-a22bf8d6f3ac',
    firstName: 'July',
    lastName: 'Ma',
  );
  final _user2 = const types.User(
    id: '82091008-a484-4a89-ae75-a22bf8d6f3ac2',
    firstName: 'Aimy',
  );

  @override
  void initState() {
    chatConnect = ChatConnect(
      url: 'wss://aimy.prod.ulu.systems/chat/websocket/',
    )..initState();
    super.initState();
  }

  @override
  void dispose() {
    chatConnect.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => chatConnect),
        ],
        child: Consumer<ChatConnect>(builder: (context, _, child) {
          return Chat(
            dateHeaderThreshold: 300000,
            messages: chatConnect.messages,
            onSendPressed: _handleSendPressed,
            user: _user,
            showUserAvatars: true,
            onMessageTap: (context, message) {
              WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
            },
            avatarBuilder: (avatarBuilder) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: widget.svg,
                ),
              );
            },
            systemMessageBuilder: (message) {
              return Center(
                child: Column(
                  children: [
                    Container(
                      child: widget.svg,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                          child: Text(
                        text1,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 30.0,
                        right: 30.0,
                        top: 16,
                        bottom: 50,
                      ),
                      child: Center(child: Text(text2)),
                    ),
                  ],
                ),
              );
            },
            customMessageBuilder: (message,
                {required int messageWidth, bool? showName}) {
              if (message.metadata?['loading'] ?? false) {
                return LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.grey.shade400,
                  size: 25,
                );
              }
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: MarkdownBody(
                  data: message.metadata?['message'],
                ),
              );
            },
            bubbleBuilder: (
              widget, {
              required types.Message message,
              required bool nextMessageInGroup,
            }) {
              return Bubble(
                color: _user.id != message.author.id ||
                        message.type == types.MessageType.image
                    ? Colors.white
                    : const Color(0xffc8c2f4),
                margin: nextMessageInGroup
                    ? const BubbleEdges.symmetric(horizontal: 6)
                    : null,
                nip: nextMessageInGroup
                    ? BubbleNip.no
                    : _user.id != message.author.id
                        ? BubbleNip.leftBottom
                        : BubbleNip.rightBottom,
                child: widget,
              );
            },
            theme: DefaultChatTheme(
              backgroundColor: Colors.grey.shade50,
            ),
          );
        }),
      );

  void _handleSendPressed(types.PartialText message) {
    WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();

    String jsonString = jsonEncode({
      'type': 'user_message',
      'content': message.text,
      'thread_id': chatConnect.threadId,
      'assistant_id': widget.assistantId,
    });

    chatConnect.addSink(jsonString);

    chatConnect.addBubble(
      types.CustomMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: randomString(),
        metadata: {
          'message': message.text,
        },
        status: types.Status.seen,
        showStatus: true,
      ),
    );

    chatConnect.addBubble(
      types.CustomMessage(
        author: _user2,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: randomString(),
        metadata: const {'loading': true},
        status: types.Status.sent,
        showStatus: true,
      ),
    );
  }
}
