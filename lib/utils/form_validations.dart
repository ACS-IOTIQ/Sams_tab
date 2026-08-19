class FormValidations {
  static emailValidation(String email, String? fieldName) {
    if (email.isEmpty) {
      return requiredFieldValidation(email, fieldName!);
    } else if (RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email)) {
      return null;
    }
    return 'Please enter valid email id';
  }

  static alternateEmailValidation(String email, String? fieldName) {
    if (email.isEmpty) {
      return requiredFieldValidation(email, fieldName!);
    } else if (RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email)) {
      return null;
    }
    return 'Alternate email id is required';
  }

  static allowMinimumSpecialCharactersValidator(String input, String text) {
    if (RegExp(r'^[a-zA-Z0-9\.\-_]+$').hasMatch(input)) {
      return null;
    }
    return "Only (.) (-) (_) special characters are allowed";
  }

  static nameCharactersValidator(String input, String text) {
    if (RegExp(r'^[a-zA-Z0-9\.\-_ ]+$').hasMatch(input)) {
      if (input.length > 50) {
        return "Characters limit restricted to 30";
      }
      return null;
    }
    return "Enter First Name is required";
  }

  // savita

  static validateAndShowToast(String input, String text, String? fieldName) {
    RegExp specialChars = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
    if (input.isEmpty) {
      return text;
    } else {
      if (specialChars.hasMatch(input) && specialChars.hasMatch(input)) {
        return "Only these special characters (.) (-) (_) are allowed";
      } else if (input[0] == "-" || input[0] == "." || input[0] == "_") {
        return "Cannot contain special character before the name";
      } else {
        if (RegExp(r'^[a-zA-Z0-9\.\-_ ]+$').hasMatch(input)) {
          if (input.length > 50) {
            return "$fieldName Name should be min 1 and max 50";
          }
          return null;
        }
      }
      //return null;
    }

    //  return null;
  }

  static phoneNoValidation(String phoneNo, String? fieldName) {
    if (phoneNo.isEmpty) {
      return requiredFieldValidation(phoneNo, fieldName!);
    } else if (phoneNo.length > 10) {
      return 'Phone Number is not more than 10 digits';
    } else if (RegExp(
      r"(((^[\+,0][9][1])(((\s[0-9]{7,10})|(\S[0-9]{7,10}))|([-]\S[0-9]{7,10})))|((^[\+,0][2]{2,2})((\S[0-9]{7,8})|((([-])[0-9]{7,8})|(\s[0-9]{7,8})))))|(((^[6,7,8,9][0-9]{9,9}))|(^[0,\+](([9][1)|[6,7,8,9]))[0-9]{8,9}))",
    ).hasMatch(phoneNo)) {
      return null;
    }
    return 'Please enter valid phone number';
  }

  /// Password Validation
  static passwordValidation(String password, String? fieldName) {
    if (password.isEmpty) {
      return requiredFieldValidation(password, fieldName!);
    }

    return null;
  }

  static createAccountpasswordValidation(String password, String? fieldName) {
    RegExp regex = RegExp(
      r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$',
    );
    if (password.isEmpty) {
      return requiredFieldValidation(password, fieldName!);
    } else if (!regex.hasMatch(password)) {
      return "Password should contain at least one Capital Letter, Small Letters, Numbers & a special character";
    } else if (password.length > 3) {
      return null;
    }
    return 'Please enter valid password';
  }

  static createAccountConfirmPasswordValidation(
    String password,
    String? fieldName,
    String cpass,
  ) {
    /*  if (passCheck != null) {
      // return CreateAccountpasswordValidation(password, fieldName);
    } else*/
    if (password != cpass) {
      return "Confirm password should be same as New Password";
    }

    return null;
  }

  static requiredFieldValidation(String? value, String fieldName) {
    if (value == null || value.trim() == '') {
      // ignore: unnecessary_string_interpolations
      return '$fieldName';
    }
    return null;
  }

  static requiredFieldValidationInCreateWithMinimumCharecters(
    String? value,
    String fieldName,
  ) {
    if (value == null || value.trim() == '') {
      return 'Field cannot be empty';
    } else if (value.trim().length < 2 || value.trim().length > 50) {
      return "Character limit: 2-50";
    }
    return null;
  }

  static captchValidation(String? value, String fieldName) {
    if (value == null || value.trim() == '') {
      return 'Field cannot be empty';
    } else if (value.isEmpty || value.length > 6) {
      return "Character limit: 1-6";
    } else if (RegExp(r'[^a-zA-Z0-9]').hasMatch(value)) {
      return "Special characters not allowed";
    }
    return null;
  }

  static requiredFieldValidationWithMinimumCharecters(
    String? value,
    String fieldName,
  ) {
    if (value == null || value.trim() == '') {
      return '$fieldName is required';
    } else if (value.length < 3) {
      return "Character limit: 3-50";
    }
    return null;
  }

  static groupFieldValidation(String? value, String fieldName) {
    if (value == null || value.trim() == '') {
      return '$fieldName is required';
    }
    return null;
  }

  static String? hasValidUrl(String value) {
    if (value.isEmpty) {
      return null;
    }
    String pattern =
        r'(http|https)://[\w-]+(\.[\w-]+)+([\w.,@?^=%&amp;:/~+#-]*[\w@?^=%&amp;/~+#-])?';
    RegExp regExp = RegExp(pattern);
    if (value.isNotEmpty && !regExp.hasMatch(value)) {
      return 'Please enter valid url';
    }
    return null;
  }

  // static String? validateField(field) {
  //   if (field.showValidation) {
  //     final value = field.meetingHistoryScrollController?.text ?? field.dropDownController?.dropDownValue?.value;
  //     if (field.isEmail) {
  //       return emailValidation(value, field.fieldName);
  //     } else if (field.isPhone) {
  //       return phoneNoValidation(value, field.fieldName);
  //     } else {
  //       return requiredFieldValidation(value, field.fieldName);
  //     }
  //   }
  //   return null;
  // }
}
