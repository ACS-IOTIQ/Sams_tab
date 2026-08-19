import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/provider/common_provider.dart';
import 'package:sams_engineering_console/ui/auth/login.dart';
import 'package:sams_engineering_console/utils/app_colors.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/common_textformfield.dart';
import 'package:sams_engineering_console/utils/custom_botton.dart';
import 'package:sams_engineering_console/utils/form_validations.dart';
import 'package:sams_engineering_console/utils/images.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<CommonProvider>(
          builder: (context, provider, child) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(AppImages.applogo),
                        height15,
                        Text("Forgot password", style: w500_15Poppins()),
                        height40,
                        Text(
                          "",
                          style: w400_14Poppins(
                            color: Theme.of(context).primaryColorDark,
                          ),
                        ),
                        height30,
                        SizedBox(
                          width: 220.w,
                          child: Column(
                            children: [
                              _emailWidget(context),
                              height10,
                              _passwordWidget(context),
                              height10,
                              _submitButton(context, provider),
                              height10,
                            ],
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Back to ', style: w400_14Poppins()),
                            InkWell(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginPage(),
                                  ),
                                );
                              },
                              child: Text("Login", style: w500_15Poppins()),
                            ),
                          ],
                        ),
                        height40,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _submitButton(BuildContext context, CommonProvider provider) {
    return CustomButton(
      buttonColor: Appcolors.buttonColor,
      buttonText: "Submit",
      onTap: () {
        // if (_formKey.currentState!.validate()) {
        //   authProvider.sendOtpRequestForForgotPassword(context: context, alternateEmailId: _emailController.text.trim());
        //   FocusScope.of(context).unfocus();
        // }
      },
    );
  }

  Widget _emailWidget(BuildContext context) {
    return CommonTextFormField(
      fillColor: Appcolors.textformFillColor,
      borderColor: Colors.grey.shade300,
      controller: _emailController,
      hintText: 'Enter Email ID',
      keyboardType: TextInputType.emailAddress,
      style: w500_14Poppins(color: Colors.white),
      validator: (val, String? fieldName) {
        return FormValidations.alternateEmailValidation(val, "Email id");
      },
      suffixIcon: Padding(
        padding: EdgeInsets.all(10.sp),
        child: Icon(Icons.mail_lock_outlined),
      ),
    );
  }

  Widget _passwordWidget(BuildContext context) {
    return CommonTextFormField(
      fillColor: Appcolors.textformFillColor,
      borderColor: Colors.grey.shade300,
      controller: _emailController,
      hintText: 'Enter current password',
      keyboardType: TextInputType.emailAddress,
      hintStyle: w400_16Poppins(),
      style: w400_15Poppins(),
      validator: (val, String? fieldName) {
        return FormValidations.passwordValidation(val, "Current password");
      },
      suffixIcon: Padding(
        padding: const EdgeInsets.all(8.0),
        child: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              isPasswordVisible = !isPasswordVisible;
            });
          },
        ),
      ),
    );
  }
}
