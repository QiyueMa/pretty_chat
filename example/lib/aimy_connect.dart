import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pretty_chat/chat.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class AimyChat extends StatefulWidget {
  const AimyChat({super.key});

  @override
  State<AimyChat> createState() => _AimyChatState();
}

class _AimyChatState extends State<AimyChat> {
  late WebSocketChannel channel;
  String? threadId;
  bool waitingForResponse = false;
  bool isSendingCustomMessage = false;
  bool needNewChatBubble = true;
  late Timer timer;

  final GlobalKey<ChatMainPageState> _chatKey = GlobalKey<ChatMainPageState>();


  @override
  void initState() {
    super.initState();
    try {
      connectToWebSocket();
    } catch (e) {
      e;
    }
  }

  @override
  void dispose() {
    timer.cancel();
    channel.sink.close(status.normalClosure);
    super.dispose();
  }

  void connectToWebSocket() async {
    const aimyURL = 'wss://aimy.prod.ulu.systems/chat/websocket/';
    channel = WebSocketChannel.connect(Uri.parse(aimyURL));
    try {
      Map<String, dynamic> data = {
        'type': 'user_message',
        'content': 'Who are you',
        'thread_id': null,
        'assistant_id': 'asst_sGUjGI1N5GTImwwdtozersbG',
      };
      String jsonString = jsonEncode(data);
      channel.sink.add(jsonString);
      channel.stream.listen((message) {
        handleAssistantMessage(message);
      },
          onError: (error) {
        print("WebSocket error: $error");
      }, onDone: () {
        print("WebSocket closed");
      });
      startKeepAlive();
    } catch (e) {
      print(e.toString());
    }
  }
  void startKeepAlive() {
    timer = Timer.periodic(Duration(seconds: 3), (timer) {
      // Send a status request to keep the connection alive
      channel.sink.add('Ping');
      print('Keep-alive message sent.');
    });
  }

  void handleAssistantMessage(String message) {
    final decodedMessage = decodeMessage(message); // Implement JSON decoding
    final sessionStorageThreadId =
        getSessionStorage('thread_id'); // Implement your session storage logic

    if (sessionStorageThreadId == null) {
      threadId = decodedMessage['thread_id'];
      setSessionStorage(
          'thread_id', threadId); // Implement your session storage logic
      postThreadId(threadId);
    }

    if (decodedMessage['content'] == null ||
        decodedMessage['content'].isEmpty) {
      return;
    }

    switch (decodedMessage['event']) {
      case 'thread.message.delta':
        handleThreadMessageDelta(decodedMessage);
        break;
      case 'tool_call.request':
        handleToolCalls(decodedMessage['content']);
        break;
      case 'custom.message.completed':
        handleCustomMessageCompleted(decodedMessage);
        break;
      case 'thread.message.completed':
        handleThreadMessageCompleted(decodedMessage);
        break;
      default:
        break;
    }
  }

  void handleThreadMessageDelta(Map<String, dynamic> message) {
    final deltaContentArray = message['content']['data']['delta']['content'];
    String? content;

    for (var deltaContent in deltaContentArray) {
      if (deltaContent['type'] == 'text') {
        content = deltaContent['text']['value'];
      }
    }

    if (content != null) {
      if (needNewChatBubble) {
        addAimyMessage();
        needNewChatBubble = false;
      }
      final formattedMessage = formatMessageContent(content);
      //updateMessage(formattedMessage, waitingForResponse);
      waitingForResponse = false;
    }
  }

  void handleCustomMessageCompleted(Map<String, dynamic> message) {
    final customContentArray = message['content']['data']['content'];
    String? content;
    String? fileId;

    for (var customContent in customContentArray) {
      if (customContent['type'] == 'text') {
        content = customContent['text']['value'];
      } else if (customContent['type'] == 'image_file') {
        fileId = customContent['image_file']['file_id'];
      }
    }

    final formattedMessage = formatMessageContent(content!);
    if (!isSendingCustomMessage) {
      isSendingCustomMessage = true;
      updateCustomMessage(formattedMessage, 0, fileId);
    }
  }

  void handleThreadMessageCompleted(Map<String, dynamic> message) {
    final completedContentArray = message['content']['data']['content'];
    String? content;
    String? fileId;
    bool imagesHandled = false;

    for (var completedContent in completedContentArray) {
      if (completedContent['type'] == 'text') {
        content = completedContent['text']['value'];
      } else if (completedContent['type'] == 'image_file') {
        imagesHandled = true;
        fileId = completedContent['image_file']['file_id'];
      }
    }

    // Handle attachments if images not handled
    if (!imagesHandled) {
      final completedAttachmentsArray =
          message['content']['data']['attachments'];
      for (var completedAttachment in completedAttachmentsArray) {
        fileId = completedAttachment['file_id'];
      }
    }

    final formattedMessage = formatMessageContent(content!);
    updateMessage(formattedMessage, true);
    if (fileId != null) {
      handleImage(fileId);
    }

    toggleUserInput(true);
  }

  void handleToolCalls(Map<String, dynamic> content) {
    // Implement your tool call handling here
  }

  void addAimyMessage() {
    // Add a new Aimy message to the UI
  }

  void updateMessage(String message, bool isCompleted) {
    // Update the message in your chat UI
    _chatKey.currentState?.addMessageFromOutside(message);
    print(message);
  }

  void updateCustomMessage(String message, int delay, String? fileId) {
    // Update the custom message in your chat UI
  }

  void handleImage(String fileId) {
    // Handle image display in your chat UI
  }

  void toggleUserInput(bool enable) {
    // Toggle user input based on the message state
  }

  String formatMessageContent(String content) {
    // Format message content for display
    return content;
  }

  void postThreadId(String? threadId) {
    // Implement your thread ID posting logic here
  }

  String? getSessionStorage(String key) {
    // Implement your session storage logic here
    return null;
  }

  void setSessionStorage(String key, String? value) {
    // Implement your session storage logic here
  }

  Map<String, dynamic> decodeMessage(String message) {
    Map<String, dynamic> jsonDecoder = jsonDecode(message);
    return jsonDecoder;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // floatingActionButton: FloatingActionButton(
      //     child: StreamBuilder(
      //       stream: channel.stream,
      //       builder: (context, snapshot) {
      //         print('${snapshot.data}');
      //         return Text(snapshot.hasData ? '${snapshot.data}' : '');
      //       },
      //     ),
      //     onPressed: () {
      //
      //       print('ping');
      //     }),
      body: ChatMainPage(
        key: _chatKey,
        onPressed: (text){
          Map<String, dynamic> data = {
            'type': 'user_message',
            'content': text.text,
            'thread_id': threadId,
            'assistant_id': 'asst_sGUjGI1N5GTImwwdtozersbG',
          };
          String jsonString = jsonEncode(data);
          channel.sink.add(jsonString);
        },
        svg: SvgPicture.asset(
          'assets/aimy.svg', // Make sure to replace with your SVG asset path
          height: 200.0,
          width: 200.0,
        ), messages: [],
      ),
    );
  }
}
