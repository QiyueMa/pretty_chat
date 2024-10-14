import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pretty_chat/chat.dart';

class AimyChat extends StatefulWidget {
  const AimyChat({super.key});

  @override
  State<AimyChat> createState() => _AimyChatState();
}

class _AimyChatState extends State<AimyChat> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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
        // onPressed: (text){
        //   Map<String, dynamic> data = {
        //     'type': 'user_message',
        //     'content': text.text,
        //     'thread_id': threadId,
        //     'assistant_id': 'asst_sGUjGI1N5GTImwwdtozersbG',
        //   };
        //   String jsonString = jsonEncode(data);
        //   channel.sink.add(jsonString);
        // },
        svg: SvgPicture.asset(
          'assets/aimy.svg', // Make sure to replace with your SVG asset path
          height: 200.0,
          width: 200.0,
        ),
        //messages: [],
      ),
    );
  }
}
