import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/provider/common_provider.dart';
import 'package:sams_engineering_console/provider/get_structure_provider.dart';
import 'package:sams_engineering_console/ui/auth/forgot_password.dart';
import 'package:sams_engineering_console/ui/auth/register.dart';
import 'package:sams_engineering_console/utils/app_colors.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/common_textformfield.dart';
import 'package:sams_engineering_console/utils/form_validations.dart';
import 'package:sams_engineering_console/utils/images.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer2<CommonProvider, GetstructureProvider>(
        builder: (context, provider, getstructureProvider, child) {
          return Form(
            key: _formKey,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  color: Colors.white,
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        children: [
                          height70,
                          height70,
                          height50,
                          Center(child: Image.asset(AppImages.applogo)),
                          height20,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Welcome To Iddc", style: w600_24Poppins()),
                              width5,
                              Image.asset(AppImages.hello),
                            ],
                          ),
                          height5,
                          Text(
                            "Hi, there youâ€™ve been missed",
                            style: w400_15Poppins(
                              color: Appcolors.lightTextColor,
                            ),
                          ),
                          height30,
                          SizedBox(
                            width: 220.w,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Email Address", style: w500_15Poppins()),
                                height5,
                                SizedBox(
                                  height: 40.h,
                                  child: CommonTextFormField(
                                    fillColor: Appcolors.textformFillColor,
                                    hintText: "Enter your email Id",
                                    controller: provider.emailLoginController,
                                    labelStyle: w400_15Poppins(),
                                    hintStyle: w400_15Poppins(),
                                    borderColor: Colors.grey.shade400,
                                    validator: (val, String? f) {
                                      return FormValidations.emailValidation(
                                        val,
                                        "Email Id",
                                      );
                                    },
                                  ),
                                ),
                                Text("Password", style: w500_15Poppins()),
                                height5,
                                CommonTextFormField(
                                  obscureText: !isPasswordVisible,
                                  fillColor: Appcolors.textformFillColor,
                                  controller: provider.passwordLoginController,
                                  hintText: "Enter your password",
                                  borderColor: Colors.grey.shade400,
                                  labelStyle: w400_15Poppins(),
                                  hintStyle: w400_14Poppins(),
                                  validator: (val, String? f) {
                                    return FormValidations.passwordValidation(
                                      val,
                                      "Password",
                                    );
                                  },
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        isPasswordVisible = !isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    _formKey.currentState!.reset();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: 15.w,
                                        top: 10.h,
                                      ),
                                      child: Text(
                                        "Forgot Password?",
                                        style: w400_16Poppins(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          height15,
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            width: 220.w,
                            height: 40.h,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Appcolors.buttonColor,
                                disabledBackgroundColor: Appcolors.buttonColor,
                              ),
                              onPressed: provider.isLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState?.validate() ??
                                          false) {
                                        provider.signIn(context);
                                      }
                                    },
                              child: provider.isLoading
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'Login',
                                      style: w500_14Poppins(
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          height5,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an Account? ",
                                style: w400_15Poppins(color: Colors.black),
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegisterScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Register",
                                  style: w500_15Poppins(
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
