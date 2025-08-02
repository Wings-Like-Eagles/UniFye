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
  final List<String> interests = [
    'Golf',
    'Cricket',
    'Football',
    'Basketball',
    'Swimming',
    'Tennis',
    'Running',
  ];
  List<String> selectedInterests = []; // To track selections

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
                // ✅ Animated Step Indicator
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Text(
                    "Step ${currentStep + 1} of $totalSteps",
                    key: ValueKey(currentStep), // Important for animation
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      color: Color(0xFF6A0572),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ✅ Animated Progress Bar
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 400),
                  tween: Tween(begin: 0.0, end: progress),
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    color: const Color(0xFFFF5C8D),
                    backgroundColor: Colors.grey[300],
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 40),

                // ✅ Dynamic Step Content
                if (currentStep == 0) ...[
                  TextField(decoration: InputDecoration(labelText: 'Name')),
                  const SizedBox(height: 20),
                  TextField(decoration: InputDecoration(labelText: 'Email')),
                ] else if (currentStep == 1) ...[
                  TextField(
                      obscureText: true,
                      decoration: InputDecoration(labelText: 'Password')),
                  const SizedBox(height: 20),
                  TextField(
                      obscureText: true,
                      decoration:
                          InputDecoration(labelText: 'Re-enter Password')),
                ] else if (currentStep == 2) ...[
                  const Text(
                    "Select Your Interests",
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A0572),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Wrap(
  spacing: 12,
  runSpacing: 12,
  children: interests.map((interest) {
    final isSelected = selectedInterests.contains(interest);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedInterests.remove(interest);
          } else {
            selectedInterests.add(interest);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF5C8D) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF5C8D) : Colors.grey.shade400,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF5C8D).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.white : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              interest,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF6A0572),
              ),
            ),
          ],
        ),
      ),
    );
  }).toList(),
),
                ],

                const SizedBox(height: 40),

                // ✅ Navigation Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous Arrow
                    ElevatedButton(
                      onPressed: currentStep == 0 ? null : previousStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5C8D),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),

                    // Next Arrow
                    ElevatedButton(
                      onPressed:
                          currentStep == totalSteps - 1 ? null : nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5C8D),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                      ),
                      child:
                          const Icon(Icons.arrow_forward, color: Colors.white),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // ✅ Already have account link
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
