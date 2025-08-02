import 'package:flutter/material.dart';
import 'package:unifye/widgets/custom-button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  static const routeName = '/register';

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  int currentStep = 0; // Tracks the current step
  final int totalSteps = 3; // Change this based on how many steps your form has

  void nextStep() {
    setState(() {
      if (currentStep < totalSteps - 1) {
        currentStep++;
      }
    });
  }

  void previousStep() {
    setState(() {
      if (currentStep > 0) {
        currentStep--;
      }
    });
  }
  @override
  Widget build(BuildContext context) {
     double progress = (currentStep + 1) / totalSteps;

    return Scaffold(
      body: Center(
        child: Container(
          width: 300,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                const Text(
                  "Register",
                  style: TextStyle(
                    fontSize: 32,
                    fontFamily: 'Poppins',
                    color: Color(0xFFFF5C8D),
                  ),
                ),
                const SizedBox(height: 20),

                // Progress Bar
                LinearProgressIndicator(
                  value: progress,
                  color: const Color(0xFFFF5C8D),
                  backgroundColor: Colors.grey[300],
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 40),

                // Step 0
                if (currentStep == 0) ...[
                  TextField(decoration: InputDecoration(labelText: 'Name')),
                  const SizedBox(height: 20),
                  TextField(decoration: InputDecoration(labelText: 'Email')),
                ]
                // Step 1
                else if (currentStep == 1) ...[
                  TextField(
                      obscureText: true,
                      decoration: InputDecoration(labelText: 'Password')),
                  const SizedBox(height: 20),
                  TextField(
                      obscureText: true,
                      decoration:
                          InputDecoration(labelText: 'Re-enter Password')),
                ]
                // Step 2
                else if (currentStep == 2) ...[
                  const Text("Final step - Review your information"),
                ],

                const SizedBox(height: 40),

                // Arrow Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous Arrow
                    ElevatedButton(
                      onPressed: previousStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5C8D),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),

                    // Next Arrow
                    ElevatedButton(
                      onPressed: nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5C8D),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Icon(Icons.arrow_forward, color: Colors.white),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Already have account link
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: const Text(
                    "Already have an account? Login",
                    style: TextStyle(
                      color: Color(0xFF6A0572),
                      fontFamily: 'Poppins',
                    ),
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
