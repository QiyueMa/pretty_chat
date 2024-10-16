import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pretty_chat/pretty_chat.dart';
import 'package:simple_shadow/simple_shadow.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Aimy',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.circle,
                    color: Colors.green,
                    size: 10,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 4.0),
                    child: Text(
                      'Online',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
        body: ChatMainPage(
          svg: SimpleShadow(
            opacity: 0.6, // Default: 0.5
            color: Colors.black, // Default: Black
            offset: const Offset(5, 5), // Default: Offset(2, 2)
            sigma: 7,
            child: SvgPicture.asset(
              'assets/aimy.svg', // Make sure to replace with your SVG asset path
              height: 200.0,
              width: 200.0,
            ), // Default: 2
          ),
          assistantId: 'asst_sGUjGI1N5GTImwwdtozersbG',
        ),
      ),
    );
  }
}
