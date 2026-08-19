import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sams_engineering_console/ui/auth/introslider/custom_slide.dart';
import 'package:sams_engineering_console/ui/auth/introslider/indicator.dart';
import 'package:sams_engineering_console/ui/auth/login.dart';
import 'package:sams_engineering_console/utils/app_colors.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/custom_botton.dart';
import 'package:sams_engineering_console/utils/images.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroSliderScreen extends StatefulWidget {
  const IntroSliderScreen({super.key});

  @override
  State<IntroSliderScreen> createState() => _IntroSliderScreenState();
}

class _IntroSliderScreenState extends State<IntroSliderScreen> {
  PageController controller = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    controller.addListener(() {
      setState(() {});
    });
  }

  void _onPageChanged(int page) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentPage = page;
    });
    await prefs.setInt('intro_slider_page', page);
    print('Saved page updated to $page'); // Debug print
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color:  Colors.white,
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.white,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      controller: controller,
                      itemCount: 4,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) {
                        return CustomSlide(idx: index, controller: controller);
                      },
                    ),
                  ],
                ),
              ),
            ),
            height10,
            Indicator(controller: controller),
            height10,
            CustomButton(
              buttonText: _currentPage == 3 ? "GET STARTED" : "NEXT",
              borderRadius: 10.r,
              buttonTextStyle: w700_15Poppins(color: Colors.white),
              width: 200.w,
              buttonColor: Appcolors.buttonColor,
              onTap: () async {
                if (_currentPage == 3) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('intro_slider_page');
                  await prefs.setBool('intro_seen', true);

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                  print("Finished!");
                } else {
                  controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
