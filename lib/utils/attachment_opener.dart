import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/provider/common_provider.dart';
import 'package:sams_engineering_console/provider/quantification_provider.dart';
import 'package:sams_engineering_console/utils/custom_toast.dart';

class AttachmentOpener {
  static Future<void> openLocal(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        await CustomToast.showErrorToast(msg: result.message);
      }
    } catch (_) {
      await CustomToast.showErrorToast(msg: 'Unable to open this file.');
    }
  }

  static Future<void> openRemote(BuildContext context, String url) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 2),
        followRedirects: false,
      ),
    );
    try {
      final base = Uri.parse(QuantificationProvider.baseUrl);
      final uri = base.resolve(url);
      if (uri.scheme != 'https' && uri.scheme != 'http') {
        throw const FormatException('Invalid attachment URL');
      }
      final provider = context.read<CommonProvider>();
      final authenticated = uri.origin == base.origin;
      Future<Response<List<int>>> fetch() => dio.get<List<int>>(
        uri.toString(),
        options: Options(
          responseType: ResponseType.bytes,
          headers: authenticated
              ? {'Authorization': 'Bearer ${provider.accessToken}'}
              : null,
          validateStatus: (status) => status == 200 || status == 401,
        ),
      );
      var response = await fetch();
      if (response.statusCode == 401 && authenticated && context.mounted) {
        if (await provider.refreshAccessToken(context)) {
          response = await fetch();
        }
      }
      if (response.statusCode != 200 ||
          response.data == null ||
          response.data!.isEmpty) {
        throw const FormatException('Attachment download failed');
      }
      final directory = await (await getTemporaryDirectory()).createTemp(
        'attachment_',
      );
      final name = path
          .basename(uri.path)
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final file = File(
        path.join(directory.path, name.isEmpty ? 'attachment' : name),
      );
      await file.writeAsBytes(response.data!, flush: true);
      await openLocal(file.path);
    } catch (_) {
      await CustomToast.showErrorToast(
        msg: 'Unable to download or open the attachment. Please try again.',
      );
    } finally {
      dio.close();
    }
  }
}
