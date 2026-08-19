import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/provider/common_provider.dart';
import 'package:sams_engineering_console/ui/auth/login.dart';
import 'package:sams_engineering_console/utils/app_colors.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/common_textformfield.dart';
import 'package:sams_engineering_console/utils/form_validations.dart';
import 'package:sams_engineering_console/utils/images.dart';
import 'package:sams_engineering_console/utils/password_validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<CommonProvider>(
        builder: (context, provider, child) {
          return Form(
            key: _formKey,

            child: SingleChildScrollView(
              child: Column(
                children: [
                  height70,
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

                  SizedBox(
                    width: 220.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        height10,

                        Text("Name", style: w500_15Poppins()),
                        height5,
                        CommonTextFormField(
                          fillColor: Appcolors.textformFillColor,
                          controller: provider.nameRegisterController,
                          hintText: "Enter your Name",
                          validator: (val, String? f) {
                            return FormValidations.nameCharactersValidator(
                              val,
                              "Name is required",
                            );
                          },
                          borderColor: Colors.grey.shade400,
                          labelStyle: w400_15Poppins(),
                          hintStyle: w400_14Poppins(),
                        ),
                        height10,
                        Text("Email Address", style: w500_15Poppins()),
                        height5,
                        CommonTextFormField(
                          fillColor: Appcolors.textformFillColor,
                          hintText: "Enter your email Id",
                          controller: provider.emailRegisterController,
                          validator: (val, String? f) {
                            return FormValidations.emailValidation(
                              val,
                              "Email Id",
                            );
                          },
                          labelStyle: w400_15Poppins(),
                          hintStyle: w400_14Poppins(),
                          borderColor: Colors.grey.shade400,
                        ),
                        height10,

                        Text("Password", style: w500_15Poppins()),
                        height5,
                        Column(
                          children: [
                            CommonTextFormField(
                              fillColor: Appcolors.textformFillColor,
                              hintText: "Enter your password",
                              obscureText: !isPasswordVisible,
                              keyboardType: TextInputType.visiblePassword,
                              controller:
                                  provider.newPasswordRegisterController,
                              onChanged: (changed) {
                                provider.passwordValidator(changed, false);
                              },
                              validator: (val, String? f) {
                                if ((provider
                                        .passwordValidState
                                        .password
                                        .isNotEmpty) &&
                                    !provider
                                        .passwordValidState
                                        .isValidPassWord) {
                                  return "Password is required";
                                } else {
                                  return FormValidations.passwordValidation(
                                    val,
                                    "Password",
                                  );
                                }
                                // return FormValidations.passwordValidation(val, "Password");
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
                              borderColor: Colors.grey.shade400,
                              labelStyle: w400_15Poppins(),
                              hintStyle: w400_14Poppins(),
                            ),
                            if ((provider
                                    .passwordValidState
                                    .password
                                    .isNotEmpty) &&
                                !provider.passwordValidState.isValidPassWord)
                              PasswordValidators.passwordInfoWidget(
                                provider.passwordValidState,
                                context,
                              ),
                          ],
                        ),
                        height10,

                        Text("Confirm Password", style: w500_15Poppins()),
                        height5,
                        CommonTextFormField(
                          obscureText: !isConfirmPasswordVisible,
                          keyboardType: TextInputType.visiblePassword,
                          controller:
                              provider.confirmPasswordRegisterController,
                          fillColor: Appcolors.textformFillColor,
                          hintText: "Enter confirm password",
                          borderColor: Colors.grey.shade400,
                          validator: (value, String? fieldName) {
                            return FormValidations.createAccountConfirmPasswordValidation(
                              value,
                              "confirm password",
                              provider.newPasswordRegisterController.text,
                            );
                          },
                          labelStyle: w400_15Poppins(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isConfirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                isConfirmPasswordVisible =
                                    !isConfirmPasswordVisible;
                              });
                            },
                          ),
                          hintStyle: w400_14Poppins(),
                        ),
                        height10,

                        Text("Designation", style: w500_15Poppins()),
                        height5,
                        CommonTextFormField(
                          fillColor: Appcolors.textformFillColor,
                          borderColor: Colors.grey.shade400,
                          validator: (val, String? f) {
                            return FormValidations.requiredFieldValidationInCreateWithMinimumCharecters(
                              val,
                              "Designation is required",
                            );
                          },
                          hintText: "Enter your designation",
                          controller: provider.designationRegisterController,
                          labelStyle: w400_15Poppins(),
                          hintStyle: w400_14Poppins(),
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
                            ),
                            onPressed: provider.isLoadingSignUp
                                ? null
                                : () {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      provider.signUp(context);
                                    }
                                  },
                            child: Text(
                              'Register',
                              style: w500_14Poppins(color: Colors.white),
                            ),
                          ),
                        ),

                        height5,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an Account? ",
                              style: w400_15Poppins(color: Colors.black),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                );
                              },
                              child: Text(
                                "Login",
                                style: w500_15Poppins(color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ],
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
