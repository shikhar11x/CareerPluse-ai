import 'package:flutter/material.dart';

class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key, required this.interviewId});

  final String interviewId;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Interview room $interviewId')));
}