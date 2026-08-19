import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/provider/common_provider.dart';
import 'package:sams_engineering_console/ui/auth/introslider/introslider_screen.dart';
import 'package:sams_engineering_console/ui/home_screen.dart';
import 'package:sams_engineering_console/utils/images.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nextFunction();
    });
  }

  void nextFunction() async {
    final commonProvider = Provider.of<CommonProvider>(context, listen: false);
    await commonProvider.loadPersistedSession();

    // Optional delay to simulate splash
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final token = commonProvider.accessToken;

    if (token.trim().isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const IntroSliderScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        child: SizedBox.expand(
          child: Image.asset(
            AppImages.onboardingImage,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
