import 'package:flutter/material.dart';
import 'package:unifye/widgets/custom-button.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 300,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Login", style: TextStyle(fontSize: 32, fontFamily: 'Poppins', color: Color(0xFFFF5C8D))),
                const SizedBox(height: 60),
                TextField(
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 40),
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Password'),
                ),
                     const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "FORGOT PASSWORD?",
                    style: TextStyle(
                      color: Color(0xFF6A0572),
                         fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(height: 80),
                MyCustomButton(
                  text: 'Login',
                  onPressed: () {
                    // Handle login action here
                    print('Login pressed!');
                  },
                ),
                const SizedBox(height: 40),
                Text(
                  "HAVE AN ACCOUNT?",
                  style: TextStyle(
                    color: Color(0xFF6A0572),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
