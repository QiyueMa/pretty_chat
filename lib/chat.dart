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
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

String randomString() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}

class ChatMainPage extends StatefulWidget {
  final Widget svg;
  const ChatMainPage({
    super.key,
    required this.svg,
  });

  @override
  State<ChatMainPage> createState() => ChatMainPageState();
}

class ChatMainPageState extends State<ChatMainPage> {
  late WebSocketChannel channel;
  String? threadId;
  bool waitingForResponse = false;
  bool isSendingCustomMessage = false;
  bool needNewChatBubble = true;
  late Timer timer;
  bool buberComplete = true;

  List<Widget> _messagesWidget = [];
  String _currentString = '';
  late List<types.Message> _messages = [];
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
    _messages = [
      types.SystemMessage(
        id: 'system-0',
        text: '',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    ];
    try {
      connectToWebSocket();
    } catch (e) {
      e;
    }
    super.initState();
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
      // Map<String, dynamic> data = {
      //   'type': 'user_message',
      //   'content': 'Who are you',
      //   'thread_id': null,
      //   'assistant_id': 'asst_sGUjGI1N5GTImwwdtozersbG',
      // };
      // String jsonString = jsonEncode(data);
      // channel.sink.add(jsonString);
      channel.stream.listen((message) {
        handleAssistantMessage(message);
      }, onError: (error) {
        if (kDebugMode) {
          print("WebSocket error: $error");
        }
      }, onDone: () {
        if (kDebugMode) {
          print("WebSocket closed");
        }
      });
      startKeepAlive();
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  void startKeepAlive() {
    timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // Send a status request to keep the connection alive
      Map<String, dynamic> data = {
        'type': 'Keep-alive',
      };
      String jsonString = jsonEncode(data);
      channel.sink.add('ping');
      if (kDebugMode) {
        print('Keep-alive message sent.');
      }
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

    if (kDebugMode) {
      print(decodedMessage);
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
        buberComplete = true;
        handleThreadMessageCompleted(decodedMessage);
        break;
      default:
        break;
    }
  }

  void handleThreadMessageDelta(Map<String, dynamic> message) {
    final deltaContentArray = message['content']['data']['delta']['content'];
    String? content;
    String? fileId;
    bool imagesHandled = false;

    for (var deltaContent in deltaContentArray) {
      if (deltaContent['type'] == 'text') {
        content = deltaContent['text']['value'];
      } else if (deltaContentArray['type'] == 'image_file') {
        imagesHandled = true;
        fileId = deltaContentArray['image_file']['file_id'];
      }
    }

    // Handle attachments if images not handled
    // if (!imagesHandled) {
    //   final completedAttachmentsArray =
    //   message['content']['data']['attachments'];
    //   for (var completedAttachment in completedAttachmentsArray) {
    //     fileId = completedAttachment['file_id'];
    //   }
    // }

    if (content != null) {
      if (needNewChatBubble) {
        addAimyMessage();
        needNewChatBubble = false;
      }
      final formattedMessage = formatMessageContent(content);
      updateMessage(formattedMessage, waitingForResponse);
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
    //updateMessage(formattedMessage, true);
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
    addMessageFromOutside(message);
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
  Widget build(BuildContext context) => Scaffold(
        body: Chat(
          dateHeaderThreshold: 300000,
          messages: _messages,
          onSendPressed: _handleSendPressed,
          user: _user,
          //showUserNames: true,
          showUserAvatars: true,
          avatarBuilder: (avatarBuilder) {
            return Container(
              width: 30,
              height: 30,
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
            );
          },
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
            //List<Widget> messagesWidget = message.metadata?['message'];
            //final imageUrls = _extractImageUrls(text);
            if(message.metadata?['loading']??false){
              return  LoadingAnimationWidget.staggeredDotsWave(
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
        ),
      );

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void addMessageFromOutside(String text) {
    if (buberComplete) {
      _currentString = text;
      final textMessage = types.CustomMessage(
        author: _user2,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: randomString(),
        metadata: {'message': _currentString},
        status: types.Status.sent,
        showStatus: true,
      );
      setState(() {
        //_messages.removeAt(0);
        //_messages.insert(0, textMessage);
        _messages.first = _messages.first.copyWith(metadata: {
          'message': _currentString,
        });
        buberComplete = false;
      });
    } else {
      /// change message only
      setState(() {
        //List<String> images = _extractImageUrls(_currentString + text);

        ///if with image
        // if(false){
        //   _currentString = _currentString + text;
        //   _messagesWidget.add(Image.network(images.last));
        //   _currentString = '';
        //   _messagesWidget.add(Text(_currentString));
        // }else{
        //   _currentString = _currentString + text;
        //   _messagesWidget.last = Text(_currentString);
        // }
        _currentString = _currentString + text;
        _messages.first = _messages.first.copyWith(metadata: {
          'message': _currentString,
        });
      });
    }
  }

  void _handleSendPressed(types.PartialText message) {
    WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();

    Map<String, dynamic> data = {
      'type': 'user_message',
      'content': message.text,
      'thread_id': threadId,
      'assistant_id': 'asst_sGUjGI1N5GTImwwdtozersbG',
    };
    String jsonString = jsonEncode(data);
    channel.sink.add(jsonString);
    final textMessage = types.CustomMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: randomString(),
      metadata: {
        'message': message.text,
      },
      status: types.Status.seen,
      showStatus: true,
    );

    _addMessage(textMessage);


    final newMessage = types.CustomMessage(
      author: _user2,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: randomString(),
      metadata: const {'loading': true},
      status: types.Status.sent,
      showStatus: true,
    );
    setState(() {
      _addMessage(newMessage);
      buberComplete = true;
    });

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

  // Method to extract all image URLs from the text
  List<String> _extractImageUrls(String text) {
    final urlPattern = RegExp(
      r'(https?:\/\/.*\.(?:png|jpg|jpeg|gif))',
      caseSensitive: false,
    );

    return urlPattern.allMatches(text).map((match) => match.group(0)!).toList();
  }
}
