import 'package:flutter/material.dart';

class ForgotPassword extends StatefulWidget {
  static const routeName = '/forgotpassword';
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  late final TextEditingController _emailController;
  late final _formkey = GlobalKey<FormFieldState>();

  @override
  void initState() {
    if (mounted) {
      _emailController = TextEditingController();
    }
    super.initState();
  }

  @override
  void dispose() {
    if (mounted) {
      _emailController.dispose();
    }
    super.dispose();
  }
  Future<void> _forgotPasswordFn()async{
      
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
