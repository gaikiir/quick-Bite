import 'package:flutter/material.dart';

class Userdarshboar extends StatefulWidget {
  static const routeName = '/UserDashboard';
  const Userdarshboar({super.key});

  @override
  State<Userdarshboar> createState() => _UserdarshboarState();
}

class _UserdarshboarState extends State<Userdarshboar> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('user dashboard')));
  }
}
