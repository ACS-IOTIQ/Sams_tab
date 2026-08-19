import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/provider/common_provider.dart';
import 'package:sams_engineering_console/utils/app_colors.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/custom_toast.dart';
import 'package:sams_engineering_console/utils/images.dart';

// ignore: must_be_immutable
class RegisterOtpScreen extends StatefulWidget {
  RegisterOtpScreen({super.key, this.phoneNumber});
  String? phoneNumber;

  @override
  State<RegisterOtpScreen> createState() => _RegisterOtpScreenState();
}

class _RegisterOtpScreenState extends State<RegisterOtpScreen> {
  String otp = '';
  final formKey = GlobalKey<FormState>();
  final TextEditingController _pinPutcontroller = TextEditingController();
  bool _isButtonEnabled = true;
  late CommonProvider commonProvider;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;
  bool hasResent = false;

  void startResendTimer() {
    setState(() {
      hasResent = true;
      _remainingSeconds = 30;
    });

    _countdownTimer?.cancel(); // cancel any existing timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds == 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
        });
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  // Update the button state when text changes
  void _onTextChanged() {
    setState(() {
      _isButtonEnabled =
          _pinPutcontroller.text.isNotEmpty; // Check if the text is not empty
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pinPutcontroller.removeListener(_onTextChanged);
    _pinPutcontroller.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    commonProvider = Provider.of<CommonProvider>(context, listen: false);
    startResendTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Enter the verification code",
          style: w500_17Poppins(color: const Color(0xff11271D)),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SvgPicture.asset(AppImages.applogo),
          ),
        ],
      ),
      body: Consumer<CommonProvider>(
        builder: (context, provider, child) {
          return Form(
            key: formKey,
            child: Center(
              child: Column(
                children: [
                  height20,
                  height70,
                  height70,
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Pinput(
                      controller: _pinPutcontroller,
                      length: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      defaultPinTheme: PinTheme(
                        width: 50,
                        height: 56,
                        textStyle: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).hintColor,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (pin) {
                        setState(() {
                          otp = pin;
                        });
                      },
                    ),
                  ),
                  height5,
                  SizedBox(
                    width: 350,
                    height: 40,
                    child: Text(
                      "We have sent a 6-digit verification code on your phone number ending with ${provider.emailRegisterController.text}",
                      style: w400_16Poppins(color: const Color(0xff11271D)),
                    ),
                  ),
                  height30,
                  if (_remainingSeconds > 0)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Resend OTP in $_remainingSeconds sec...",
                            style: w400_16Poppins(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  else
                    InkWell(
                      onTap: provider.isLoadingSignUp
                          ? null
                          : () {
                              // provider.resendOtpSignUp(provider.phoneSignUpController.text,_pinPutcontroller.text,context);
                              provider.signUp(context);
                              startResendTimer(); // Restart timer after resend
                            },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Resend OTP",
                              style: w500_14Poppins(
                                color: Appcolors.buttonColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  height20,
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: SizedBox(
                      height: 40,
                      width: 350,
                      child: ElevatedButton(
                        onPressed: provider.isSignedIn
                            ? null
                            : () {
                                if (formKey.currentState?.validate() ?? false) {
                                  if (otp.length < 6) {
                                    CustomToast.showErrorToast(
                                      msg: "Please Enter valid otp",
                                    );
                                    return;
                                  }
                                  provider.verifyOtpSignup(
                                    _pinPutcontroller.text,
                                    context,
                                  );
                                }
                              }, // Button is disabled when _isButtonEnabled is false
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Appcolors
                              .buttonColor, // Button color changes based on state
                          // onSurface: Colors.grey, // Color for disabled state (onPressed is null)
                        ),
                        child: Text(
                          'Verify',
                          style: w500_14Poppins(
                            color: _isButtonEnabled
                                ? Colors.white
                                : const Color.fromARGB(255, 20, 28, 24),
                          ),
                        ),
                      ),
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
