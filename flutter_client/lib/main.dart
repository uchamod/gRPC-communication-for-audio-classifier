import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(),
      home: Scaffold(),
    );
  }
}
//to switch to new remote branch that not track in locally
// git branch -m develop main
// git fetch origin
// git branch -u origin/main main
// git remote set-head origin -a