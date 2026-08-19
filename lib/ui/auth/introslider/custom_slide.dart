import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sams_engineering_console/ui/auth/login.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/images.dart';

class CustomSlide extends StatelessWidget {
  final int idx;
  final PageController controller;

  const CustomSlide({super.key, required this.idx, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    color: Colors.white,
                    child: Stack(
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 0.55,
                          child: Image.asset(
                            customSlideLst[idx].image,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.of(context).size.height * 0.45,
                          width: MediaQuery.of(context).size.width,
                          child: Image.asset(
                            AppImages.backgroundImageIntro,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Positioned(
                          top: 15.h,
                          right: 10.w,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginPage(),
                                ),
                              );
                            },
                            child: Text(
                              "Skip",
                              style: w600_24Poppins(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  height50,
                  height50,
                  Text(
                    customSlideLst[idx].key,
                    maxLines: 3,
                    textAlign: TextAlign.center,
                    style: w600_20Poppins(color: Colors.black),
                  ),
                  height10,
                  SizedBox(
                    height: 60.h,
                    width: 250.w,
                    child: Text(
                      customSlideLst[idx].key1,
                      maxLines: 4,
                      textAlign: TextAlign.center,
                      style: w400_17Poppins(color: const Color(0xff636363)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CustomSlideModel {
  String key;
  String key1;
  String image;

  CustomSlideModel({
    required this.key,
    required this.key1,
    required this.image,
  });
}

List<CustomSlideModel> customSlideLst = [
  CustomSlideModel(
    image: AppImages.splashImage1,
    key: '''Welcome to IDDC India''',
    key1: '''Empowering Growth Through Innovative Solutions''',
  ),
  CustomSlideModel(
    image: AppImages.splashImage2,
    key: '''Our Mission''',
    key1:
        '''Empower organizations with innovative infrastructure solutions that ensure long-term success and sustainability''',
  ),
  CustomSlideModel(
    image: AppImages.splashImage3,
    key: '''We Communicate Effectively with our Clients''',
    key1:
        '''Ensuring timely quality services, by fostering open communication and establishing clear expectations from the outset, we ensure that our projects align with client goals and deadlines.''',
  ),
  CustomSlideModel(
    image: AppImages.splashImage4,
    key: '''Our Vision''',
    key1:
        '''Lead the future of infrastructure development by leveraging technology, expertise, and a deep understanding of the industries we serve. We aim to create smarter, more resilient infrastructure that meets the demands of tomorrow’s world.''',
  ),
];
