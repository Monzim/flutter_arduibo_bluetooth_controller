import 'package:flutter/material.dart';

import 'main_page.dart';

void main() => runApp(
      const ExampleApplication(),
    );

class ExampleApplication extends StatelessWidget {
  const ExampleApplication({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MainPage(),
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
    );
  }
}
