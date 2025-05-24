

import 'package:flutter/material.dart';
import 'package:unifye/widgets/custom-button.dart';

class LoginPage extends StatelessWidget {
   const LoginPage({super.key});


    @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Login", style: TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(labelText: 'Email'),

              ),
              const SizedBox(height: 10),
              TextField(
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 20),
              MyCustomButton(
                text: 'Login',
                onPressed: () {
                  // Handle login action here
                  print('Login pressed!');
                },
              ),
            ],
          ),
           
        ),
        ),
       

      ),
    );
  }
}