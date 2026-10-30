import 'package:flutter/material.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.interviewId});

  final String interviewId;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Results $interviewId')));
}