import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

// For the testing purposes, you should probably use https://pub.dev/packages/uuid.
String randomString() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}

class ChatMainPage extends StatefulWidget {
  final Widget svg;
  const ChatMainPage({super.key, required this.svg});

  @override
  State<ChatMainPage> createState() => _ChatMainPageState();
}

class _ChatMainPageState extends State<ChatMainPage> {
  String text1 = "Hi. how can I help you?";
  String text2 =
      "I'm Aimy, your personal chatbot assistant. With access to various data and a wealth of FAQ knowledge, I'm ready to answer your questions. I can also assist you with managing your fleet!";

  late final List<types.Message> _messages;
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
    _messages = [
      types.SystemMessage(
        id: 'system-0',
        text: '',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Chat(
          messages: _messages,
          onSendPressed: _handleSendPressed,
          user: _user,
          showUserNames: true,
          systemMessageBuilder: (message) {
            return Center(
              child: Column(
                children: [
                  Container(
                    //padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(90),
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, 0),
                          blurRadius: 12,
                          spreadRadius: 0,
                          color: const Color(0xff5e5e5c).withOpacity(0.10),
                        ),
                      ],
                    ),
                    child: widget.svg,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                        child: Text(
                      text1,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    )),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 30.0, right: 30.0,
                      top: 16, bottom: 50,
                    ),
                    child: Center(child: Text(text2)),
                  ),
                ],
              ),
            );
          },
          theme: DefaultChatTheme(),
        ),
      );

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: randomString(),
      text: message.text,
      status: types.Status.sent,
      showStatus: true,
    );

    _addMessage(textMessage);
    //
    // final textMessage2 = types.TextMessage(
    //   author: _user2,
    //   createdAt: DateTime.now().millisecondsSinceEpoch,
    //   id: randomString(),
    //   text: message.text,
    //   status: types.Status.sent,
    //   showStatus: true,
    // );
    // _addMessage(textMessage2);
  }
}
