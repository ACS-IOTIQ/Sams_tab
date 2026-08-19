import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sams_engineering_console/provider/common_provider.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/images.dart';

class PasswordValidators {
  static Widget getPasswordProgressBar(
    ValidatePassWord passwordState,
    BuildContext context,
  ) {
    if (passwordState.password.isNotEmpty && !passwordState.isValidPassWord) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            List<bool> validatorList = [
              passwordState.isLowerCaseExists,
              passwordState.isUpperCaseExists,
              passwordState.isNumberExists,
              passwordState.isSpecialCharacterExists,
              passwordState.is8Characters,
              passwordState.password.length >= 10,
            ];
            int enabledLenth = validatorList.where((element) => element).length;
            return getProgressBar(
              index: index,
              enabledLength: enabledLenth,
              color: passwordState.isValidPassWord
                  ? Colors.green
                  : getValidationColor(enabledLenth),
              context: context,
            );
          }),
        ),
      );
    } else {
      return Container();
    }
  }

  static Widget getProgressBar({
    required int index,
    required Color color,
    required int enabledLength,
    required BuildContext context,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabledLength > index ? color : Colors.grey.shade500,
        borderRadius: BorderRadius.circular(10),
      ),
      height: 5,
      width: MediaQuery.of(context).size.width * 0.1,
    );
  }

  static Color getValidationColor(int index) {
    switch (index) {
      case 0:
        return Colors.grey.shade500;
      case 1:
        return Colors.red;
      case 2:
        return Colors.yellow;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.yellow;
      case 5:
        return Colors.green;
      default:
        return Colors.grey.shade500;
    }
  }

  static Padding passwordInfoWidget(
    ValidatePassWord passwordState,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("To Make your password Stronger", style: w400_14Poppins()),
              passWordStrengthText(
                "1 upper case letter",
                showColor: passwordState.isUpperCaseExists,
              ),
              passWordStrengthText(
                "1 lower case letter",
                showColor: passwordState.isLowerCaseExists,
              ),
              passWordStrengthText(
                "1 or more special characters",
                showColor: passwordState.isSpecialCharacterExists,
              ),
              passWordStrengthText(
                "1 or more numbers",
                showColor: passwordState.isNumberExists,
              ),
              passWordStrengthText(
                "8 characters should be required",
                showColor: passwordState.is8Characters,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget passWordStrengthText(
    String passwordText, {
    bool showColor = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Container(
            height: 8.w,
            width: 8.w,
            decoration: BoxDecoration(
              color: showColor ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          width5,
          Text(passwordText, style: w400_14Poppins()),
        ],
      ),
    );
  }
}
