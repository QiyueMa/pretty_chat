import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatConnect extends ChangeNotifier {
  String url;

  ChatConnect({
    required this.url,
  });

  WebSocketChannel? _channel;
  Timer? _timer;
  String _currentMessage = '';

  String? threadId;
  bool bubbleComplete = true;
  List<types.Message> messages = [
    types.SystemMessage(
      id: 'system-0',
      text: '',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ),
  ];

  void initState() async {
    await _connectToWebSocket();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _channel?.sink.close(status.normalClosure);
    super.dispose();
  }

  void addSink(String jsonString) async {
    if (kDebugMode) {
      print('Message sent: $jsonString');
    }
    try {
      _channel?.sink.add(jsonString);
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
      await _connectToWebSocket();
      _channel?.sink.add(jsonString);
    }
  }

  addBubble(Message message) {
    messages.insert(0, message);
    notifyListeners();
  }

  Future<void> _connectToWebSocket() async {
    if (kDebugMode) {
      print("Start to connect WebSocket");
    }
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel?.ready;
      _channel?.stream.listen((message) {
        _handleAssistantMessage(message);
      }, onError: (error) {
        if (kDebugMode) {
          print("WebSocket error: $error");
        }
      }, onDone: () {
        if (kDebugMode) {
          print("WebSocket closed");
        }
      });
      _startKeepAlive();
    } catch (e) {
      if (kDebugMode) {
        print(e.toString());
      }
    }
  }

  void _startKeepAlive() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // Send a status request to keep the connection alive
      addSink('ping');
      if (kDebugMode) {
        print('Keep-alive message sent.');
      }
    });
  }

  void _handleAssistantMessage(String message) {
    final decodedMessage = _decodeMessage(message);
    final sessionStorageThreadId = _getSessionStorage('thread_id');

    if (sessionStorageThreadId == null) {
      threadId = decodedMessage['thread_id'];
      _setSessionStorage('thread_id', threadId);
      _postThreadId(threadId);
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
        _handleThreadMessageDelta(decodedMessage);
        break;
      case 'thread.message.completed':
        bubbleComplete = true;
        break;
      default:
        break;
    }
  }

  void _handleThreadMessageDelta(Map<String, dynamic> message) {
    final deltaContentArray = message['content']['data']['delta']['content'];
    String? content;

    for (var deltaContent in deltaContentArray) {
      if (deltaContent['type'] == 'text') {
        content = deltaContent['text']['value'];
      }
    }

    if (content != null) {
      final formattedMessage = _formatMessageContent(content);
      _updateMessage(formattedMessage);
    }
  }

  void _updateMessage(String message) {
    if (bubbleComplete) {
      _currentMessage = message;
      messages.first = messages.first.copyWith(metadata: {
        'message': _currentMessage,
      });
      bubbleComplete = false;
    } else {
      _currentMessage = _currentMessage + message;
      messages.first = messages.first.copyWith(metadata: {
        'message': _currentMessage,
      });
    }
    notifyListeners();
  }

  String _formatMessageContent(String content) {
    return content;
  }

  void _postThreadId(String? threadId) {
    // Implement your thread ID posting logic here
  }

  String? _getSessionStorage(String key) {
    // Implement your session storage logic here
    return null;
  }

  void _setSessionStorage(String key, String? value) {
    // Implement your session storage logic here
  }

  Map<String, dynamic> _decodeMessage(String message) {
    Map<String, dynamic> jsonDecoder = jsonDecode(message);
    return jsonDecoder;
  }
}
