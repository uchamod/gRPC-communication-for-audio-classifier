import 'package:flutter/material.dart';
import 'package:flutter_client/presentation/screens/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(),
      home: HomePage(),
    );
  }
}
//to switch to new remote branch that not track in locally
// git branch -m develop main
// git fetch origin
// git branch -u origin/main main
// git remote set-head origin -a