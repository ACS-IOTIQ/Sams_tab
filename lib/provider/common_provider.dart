import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/provider/token_http_client.dart';
import 'package:sams_engineering_console/service/navigator_service.dart';
import 'package:sams_engineering_console/ui/auth/login.dart';
import 'package:sams_engineering_console/ui/auth/register_otpscreen.dart';
import 'package:sams_engineering_console/ui/home_screen.dart';
import 'package:sams_engineering_console/utils/app_fonts.dart';
import 'package:sams_engineering_console/utils/custom_toast.dart';
import 'package:sams_engineering_console/utils/images.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommonProvider extends ChangeNotifier {
  static const String _prefAccessToken = 'accessToken';
  static const String _prefLegacyAccessToken = 'access_token';
  static const String _prefRefreshToken = 'refreshToken';
  static const String _prefUserRole = 'userRole';
  static const String _prefUserName = 'username';
  static const String _prefLegacyUserName = 'user_name';
  static const String _prefIsLoggedIn = 'isLoggedIn';

  final TextEditingController phoneRegisterController = TextEditingController();
  final TextEditingController nameRegisterController = TextEditingController();
  final TextEditingController emailRegisterController = TextEditingController();
  final TextEditingController newPasswordRegisterController =
      TextEditingController();
  final TextEditingController confirmPasswordRegisterController =
      TextEditingController();
  final TextEditingController designationRegisterController =
      TextEditingController();
  final TextEditingController emailLoginController = TextEditingController();
  final TextEditingController passwordLoginController = TextEditingController();

  static const String baseUrl = 'https://sams.acstechnologies.co.in';

  ValidatePassWord passwordValidState = ValidatePassWord();

  bool _isLoading = false;
  bool _isSignedIn = false;
  bool get isSignedIn => _isSignedIn;

  bool get isLoading => _isLoading;

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  bool _isLoadingSignUp = false;
  bool get isLoadingSignUp => _isLoadingSignUp;

  void setLoadingSignUp(bool val) {
    _isLoadingSignUp = val;
    notifyListeners();
  }

  Future<void> signIn(BuildContext context) async {
    const url = '$baseUrl/api/auth/login';
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      "identifier": emailLoginController.text.trim(),
      "password": passwordLoginController.text,
    });

    setLoading(true);

    try {
      final response = await TokenAwareHttpClient.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print("API login response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final success = data['success'] ?? false;
        final message = data['message'] ?? 'Login complete';
        final token = data['accessToken'] ?? '';
        final refreshToken = data['refreshToken'] ?? '';
        final role = data['user']?['role'] ?? '';
        final userName = data['user']?['username'] ?? '';

        // Save in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefAccessToken, token);
        await prefs.setString(_prefRefreshToken, refreshToken);
        await prefs.setString(_prefUserRole, role);
        await prefs.setString(_prefUserName, userName);
        await prefs.setBool(_prefIsLoggedIn, true);
        // Clean up legacy keys if present
        await prefs.remove(_prefLegacyAccessToken);
        await prefs.remove(_prefLegacyUserName);

        // Save in Provider
        final commonProvider = Provider.of<CommonProvider>(
          context,
          listen: false,
        );
        commonProvider.setAccessToken(token);
        commonProvider.setUserRole(role);
        commonProvider.setUserName(userName);

        await saveTokens(token);

        if (success) {
          setLoading(false);
          await CustomToast.showSuccessToast(msg: message);

          if (!context.mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          setLoading(false);
          CustomToast.showErrorToast(msg: message);
        }
      } else {
        final responseData = jsonDecode(response.body);
        setLoading(false);
        CustomToast.showErrorToast(
          msg: "${responseData['error'] ?? 'Login failed'}",
        );
      }
    } catch (e) {
      print('Error: $e');
      setLoading(false);
      CustomToast.showErrorToast(msg: e.toString());
    }
  }

  String? _userRole;
  String? get userRole => _userRole;

  void setUserRole(String role) {
    _userRole = role;
    notifyListeners();
  }

  String? _userName;
  String? get userName => _userName;

  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  // Add these methods to your existing CommonProvider class

  // Method to load user role from SharedPreferences on app startup
  Future<void> loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString(_prefUserRole);
    if (savedRole != null) {
      setUserRole(savedRole);
    }
  }

  /// Load persisted auth/session data into provider state
  Future<void> loadPersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString(_prefAccessToken) ??
        prefs.getString(_prefLegacyAccessToken);
    final role = prefs.getString(_prefUserRole);
    final name =
        prefs.getString(_prefUserName) ?? prefs.getString(_prefLegacyUserName);

    if (token != null && token.trim().isNotEmpty) {
      setAccessToken(token.trim());
    }
    if (role != null && role.trim().isNotEmpty) {
      setUserRole(role.trim());
    }
    if (name != null && name.trim().isNotEmpty) {
      setUserName(name.trim());
    }
  }

  // Method to check if user is admin
  bool get isAdmin => _userRole?.toLowerCase() == 'admin';

  // Method to check if user is field engineer
  bool get isFieldEngineer => _userRole?.toLowerCase() == 'field engineer';

  // Method to get user role display name
  String get userRoleDisplay {
    if (_userRole == null) return 'Unknown';
    return _userRole!.toUpperCase();
  }

  // Updated method to clear role on logout
  Future<void> logout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefAccessToken);
    await prefs.remove(_prefLegacyAccessToken);
    await prefs.remove(_prefRefreshToken);
    await prefs.remove(_prefUserName);
    await prefs.remove(_prefLegacyUserName);
    await prefs.remove('user_id');
    await prefs.remove('mobile_number');
    await prefs.remove(_prefIsLoggedIn);
    await prefs.remove(_prefUserRole);

    _accessToken = '';
    _userRole = null;

    notifyListeners();

    await CustomToast.showSuccessToast(
      msg: "Session expired. Please login again.",
    );

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );

    _isLoggingOut = false;
  }

  Future<void> forgotPassword(BuildContext context) async {
    const url = '$baseUrl/api/auth/forgot-password';
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      "identifier": emailLoginController.text,
      "password": passwordLoginController.text,
    });

    setLoading(true);

    try {
      final response = await TokenAwareHttpClient.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print("response body login $body");

      if (response.statusCode == 200) {
        print('Success: ${response.body}');
        final responseData = jsonDecode(response.body);
        final success = responseData['success'];
        final message = responseData['message'];

        if (success == true) {
          // Show toast, then navigate
          await CustomToast.showSuccessToast(msg: message);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setLoading(false); // stop loader before navigating
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          });
        } else {
          setLoading(false);
          CustomToast.showErrorToast(msg: message);
        }
      } else {
        setLoading(false);
        print('Failed with status: ${response.statusCode}');
        final responseData = jsonDecode(response.body);
        print("singin response $responseData");
        CustomToast.showErrorToast(msg: "${responseData['error']}");
      }
    } catch (e) {
      print('Error: $e');
      setLoading(false);
      CustomToast.showErrorToast(msg: "$e");
    }
  }

  String _accessToken = '';
  String get accessToken => _accessToken;

  void setAccessToken(String token) {
    _accessToken = token;
    notifyListeners();
  }

  Future<void> saveTokens(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefAccessToken, accessToken);
    await prefs.remove(_prefLegacyAccessToken);
  }

  Future<void> signUp(BuildContext context) async {
    final url = Uri.parse('$baseUrl/api/auth/register');
    final headers = {'Content-Type': 'application/json'};

    final body = jsonEncode({
      "username": nameRegisterController.text,
      "email": emailRegisterController.text,
      "password": newPasswordRegisterController.text,
      "confirmPassword": confirmPasswordRegisterController.text,
      "role": designationRegisterController.text,
    });

    setLoadingSignUp(true);

    try {
      final response = await TokenAwareHttpClient.post(
        url,
        headers: headers, 
        body: body,
      );

      final responseData = jsonDecode(response.body);
      final success = responseData['success'] ?? false;
      final message = responseData['message'] ?? responseData['error'];

      if (success) {
        print("✅ Signup successful: $responseData");

        await CustomToast.showSuccessToast(msg: message);  

        WidgetsBinding.instance.addPostFrameCallback((_) {
          setLoadingSignUp(false);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RegisterOtpScreen()),
          );
        });
      } else {
        // This branch will never be hit in your case, but kept for safety
        setLoadingSignUp(false);
        print(
          "❌ Signup failed (API responded with success=false): $responseData",
        );
        CustomToast.showErrorToast(msg: message);
      }
    } catch (e) {
      setLoadingSignUp(false);
      print('❌ Exception during signup: $e');
      CustomToast.showErrorToast(
        msg: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> verifyOtpSignup(String otp, BuildContext context) async {
    final url = Uri.parse('$baseUrl/api/auth/verify-email');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'email': emailRegisterController.text,
      'otp': otp,
    });

    _isSignedIn = true;

    try {
      final response = await http.post(url, headers: headers, body: body);
      final data = jsonDecode(response.body);
      print("Response data: $data");

      if (data['user'] != null &&
          data['accessToken'] != null &&
          data['refreshToken'] != null) {
        final prefs = await SharedPreferences.getInstance();

        bool signUpSuccess = data['success'];
        String token = data['accessToken'];
        String refreshToken = data['refreshToken'];

        await prefs.setString(_prefAccessToken, token);
        await prefs.setString(_prefRefreshToken, refreshToken);
        await prefs.setBool('success', signUpSuccess);
        await prefs.remove(_prefLegacyAccessToken);

        // commonProvider.setAccessToken(token);

        CustomToast.showSuccessToast(msg: "${data['message']}");

        WidgetsBinding.instance.addPostFrameCallback((_) {
          setLoadingSignUp(false);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ), // ← Replace with your actual home screen
          );
        });
      } else {
        CustomToast.showErrorToast(
          msg: data['error'] ?? "OTP verification failed",
        );
      }
    } catch (e) {
      print('Error during OTP verification: $e');
      CustomToast.showErrorToast(msg: "$e");
      _isSignedIn = false;
    }
  }

  Future<bool> refreshAccessToken(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_prefRefreshToken);
    if (refreshToken == null || refreshToken.isEmpty) {
      print("⚠️ No refresh token found in SharedPreferences.");
      return false;
    }
    const url = '$baseUrl/api/auth/refresh-token';
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'refreshToken': refreshToken});
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("🔄 Token refresh response: $data");
        final newAccessToken =
            data['tokens']?['accessToken'] ?? data['accessToken'];
        final newRefreshToken =
            data['tokens']?['refreshToken'] ?? data['refreshToken'];
        print("New access token: $newAccessToken");
        print("New refresh token: $newRefreshToken");
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await prefs.setString(_prefAccessToken, newAccessToken);
          await prefs.remove(_prefLegacyAccessToken);
          setAccessToken(newAccessToken);
        } else {
          print("⚠️ Access token missing or empty in refresh response");
          logout();
          return false;
        }
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await prefs.setString(_prefRefreshToken, newRefreshToken);
        }
        print("✅ Access token refreshed successfully.");
        return true;
      } else {
        print(
          "❌ Failed to refresh token: ${response.statusCode} ${response.body}",
        );
        logout();
        return false;
      }
    } catch (e) {
      print("🔥 Error during token refresh: $e");
      logout();
      return false;
    }
  }

  bool _isLoggingOut = false;

  static Padding passwordInfoWidget(
    ValidatePassWord passwordState,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        color: Theme.of(context).primaryColor,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "To Make your password Stronger",
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
          Text(passwordText, style: w400_16Poppins(color: Colors.white)),
        ],
      ),
    );
  }

  void passwordValidator(String password, bool showPasswordInfo) {
    bool atLeastOneUpperCase = RegExp(r'''([A-Z])''').hasMatch(password);
    bool atLeastOneLowerCase = RegExp(r'''([a-z])''').hasMatch(password);
    bool atLeastOneDigit = RegExp(r"([0-9])").hasMatch(password);
    bool atLeastOneSpecialCharecter = RegExp(
      r'''[?=.*?[!@#\$&*_~]''',
    ).hasMatch(password);
    bool atLeast8Charecters = RegExp('''(.{8,})''').hasMatch(password);
    passwordValidState = ValidatePassWord(
      isLowerCaseExists: atLeastOneLowerCase,
      isNumberExists: atLeastOneDigit,
      isSpecialCharacterExists: atLeastOneSpecialCharecter,
      isUpperCaseExists: atLeastOneUpperCase,
      is8Characters: atLeast8Charecters,
      isValidPassWord:
          atLeastOneLowerCase &&
          atLeastOneDigit &&
          atLeastOneSpecialCharecter &&
          atLeast8Charecters &&
          atLeastOneUpperCase,
      password: password,
      showPassWordInfo: showPasswordInfo,
    );
    notifyListeners();
  }
}

class ValidatePassWord {
  bool isUpperCaseExists;
  bool isLowerCaseExists;
  bool isNumberExists;
  bool isSpecialCharacterExists;
  bool isValidPassWord;
  bool is8Characters;
  bool showPassWordInfo;
  String password;

  ValidatePassWord({
    this.isLowerCaseExists = false,
    this.isNumberExists = false,
    this.isSpecialCharacterExists = false,
    this.isUpperCaseExists = false,
    this.isValidPassWord = false,
    this.is8Characters = false,
    this.showPassWordInfo = false,
    this.password = "",
  });
}
