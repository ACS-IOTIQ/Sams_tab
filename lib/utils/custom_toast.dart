import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:sams_engineering_console/service/navigator_service.dart';

class CustomToast {
  static Widget crossIcon = const Icon(Icons.close);

  static Future<void> showSuccessToast({
    required String msg,
    String? title,
    Duration duration = const Duration(seconds: 2),
  }) async {
    final flush = Flushbar(
      title: title,
      message: msg,
      borderColor: Colors.green,
      messageColor: Colors.green,
      backgroundColor: Colors.white,
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(Icons.check_circle, color: Colors.green, size: 24),
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
    );

    await _showToast(flush);
  }

  static Future showWarningToast({
    required String? msg,
    Duration? duration,
  }) async {
    late Flushbar flush;

    flush = Flushbar(
      message: msg.toString(),
      backgroundColor: Colors.orange,

      // Do not close automatically
      duration: null,

      margin: const EdgeInsets.all(15),
      borderRadius: const BorderRadius.all(Radius.circular(15)),

      icon: const Icon(
        Icons.info_outline_rounded,
        color: Colors.white,
        size: 40,
      ),

      mainButton: IconButton(
        icon: const Icon(Icons.close, color: Colors.white, size: 22),
        onPressed: () {
          flush.dismiss();
        },
      ),

      padding: const EdgeInsets.all(15),
    );

    return _showToast(flush);
  }

  static Future showErrorToast({required String? msg}) async {
    late Flushbar flush;

    flush = Flushbar(
      message: msg.toString(),
      backgroundColor: Colors.white,
      messageColor: Colors.red,
      borderColor: Colors.red,

      // Do not close automatically
      duration: null,

      margin: const EdgeInsets.all(15),
      borderRadius: const BorderRadius.all(Radius.circular(15)),

      icon: const Icon(Icons.error, color: Colors.red, size: 32),

      mainButton: IconButton(
        icon: const Icon(Icons.close, color: Colors.black, size: 22),
        onPressed: () {
          flush.dismiss();
        },
      ),

      padding: const EdgeInsets.all(10),
    );

    return _showToast(flush);
  }

  static Future showInfoToast({
    required String? msg,
    Duration? duration,
  }) async {
    late Flushbar flush;

    flush = Flushbar(
      message: msg.toString(),
      messageColor: Colors.black,
      backgroundColor: Colors.white,

      // Do not close automatically
      duration: null,

      mainButton: IconButton(
        icon: const Icon(Icons.close, color: Colors.black, size: 22),
        onPressed: () {
          flush.dismiss();
        },
      ),

      margin: const EdgeInsets.all(15),
      borderRadius: const BorderRadius.all(Radius.circular(15)),
      padding: const EdgeInsets.all(15),
    );

    return _showToast(flush);
  }

  static Future showDownloadToast({
    required String msg,
    VoidCallback? onTap,
  }) async {
    late Flushbar flush;

    flush = Flushbar(
      message: msg,
      messageColor: Colors.white,
      backgroundColor: Colors.green,
      onTap: onTap == null ? null : (_) => onTap(),

      // Do not close automatically
      duration: null,

      mainButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onTap != null)
            TextButton(
              onPressed: () {
                flush.dismiss();
                onTap();
              },
              child: const Text('Open', style: TextStyle(color: Colors.white)),
            ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 22),
            onPressed: () {
              flush.dismiss();
            },
          ),
        ],
      ),

      margin: const EdgeInsets.all(15),
      borderRadius: const BorderRadius.all(Radius.circular(15)),
      padding: const EdgeInsets.all(15),
    );

    return _showToast(flush);
  }

  static Future _showToast(Flushbar flush) async {
    final context = navigatorKey.currentContext;

    if (context == null) {
      return null;
    }

    return await flush.show(context);
  }
}
