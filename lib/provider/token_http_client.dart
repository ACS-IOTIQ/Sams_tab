// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sams_engineering_console/provider/common_provider.dart';
import 'package:sams_engineering_console/service/navigator_service.dart';

class TokenAwareHttpClient {
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const int _maxAttempts = 2;

  static Future<http.Response> get(
    Object url, {
    required Map<String, String> headers,
    BuildContext? context,
  }) async {
    return _sendWithRefresh(
      context: context,
      headers: headers,
      send: (updatedHeaders) => _performRequest(
        () => http.get(_normalizeUri(url), headers: updatedHeaders),
      ),
    );
  }

  static Future<http.Response> post(
    Object url, {
    required Map<String, String> headers,
    Object? body,
    BuildContext? context,
  }) async {
    return _sendWithRefresh(
      context: context,
      headers: headers,
      send: (updatedHeaders) => _performRequest(
        () => http.post(_normalizeUri(url), headers: updatedHeaders, body: body),
      ),
    );
  }

  static Future<http.Response> put(
    Object url, {
    required Map<String, String> headers,
    required Object body,
    BuildContext? context,
  }) async {
    return _sendWithRefresh(
      context: context,
      headers: headers,
      send: (updatedHeaders) => _performRequest(
        () => http.put(_normalizeUri(url), headers: updatedHeaders, body: body),
      ),
    );
  }

  static Future<http.Response> delete(
    Object url, {
    required Map<String, String> headers,
    BuildContext? context,
  }) async {
    return _sendWithRefresh(
      context: context,
      headers: headers,
      send: (updatedHeaders) => _performRequest(
        () => http.delete(_normalizeUri(url), headers: updatedHeaders),
      ),
    );
  }

  static Future<http.Response> _sendWithRefresh({
    required Map<String, String> headers,
    required Future<http.Response> Function(Map<String, String> updatedHeaders) send,
    BuildContext? context,
  }) async {
    final updatedHeaders = Map<String, String>.from(headers);
    final activeContext = context ?? navigatorKey.currentContext;
    final provider = activeContext == null
        ? null
        : Provider.of<CommonProvider>(activeContext, listen: false);

    var response = await send(updatedHeaders);

    if (response.statusCode == 401 && provider != null) {
      final success = await provider.refreshAccessToken(activeContext!);
      if (!success || provider.accessToken.trim().isEmpty) {
        return response;
      }

      updatedHeaders['Authorization'] = 'Bearer ${provider.accessToken}';
      response = await send(updatedHeaders);
    }

    return response;
  }

  static Future<http.Response> _performRequest(
    Future<http.Response> Function() request,
  ) async {
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        return await request().timeout(_requestTimeout);
      } on SocketException catch (error) {
        if (attempt == _maxAttempts) {
          throw Exception(
            'Unable to reach the server. Please check the server URL or try again shortly. (${error.message})',
          );
        }
      } on TimeoutException {
        if (attempt == _maxAttempts) {
          throw Exception(
            'The server took too long to respond. Please try again shortly.',
          );
        }
      } on HandshakeException catch (error) {
        throw Exception(
          'Secure connection failed. Please verify the server certificate or URL. (${error.message})',
        );
      }

      await Future.delayed(const Duration(milliseconds: 700));
    }

    throw Exception('Unexpected network failure');
  }

  static Uri buildUri({
    required String baseUrl,
    String path = '',
    Map<String, dynamic>? queryParameters,
  }) {
    final base = _parseCleanUri(baseUrl);
    final cleanedPath = path.trim();
    final combinedSegments = <String>[
      ...base.pathSegments.where((segment) => segment.isNotEmpty),
      ..._splitPath(cleanedPath),
    ];
    final resolvedQuery = queryParameters == null
        ? _baseQueryOrNull(base)
        : _stringifyQuery(queryParameters);

    return base.replace(
      pathSegments: combinedSegments,
      queryParameters: resolvedQuery,
    );
  }

  static Uri _normalizeUri(Object url) {
    if (url is Uri) {
      return _parseCleanUri(url.toString());
    }
    if (url is String) {
      return _parseCleanUri(url);
    }
    throw ArgumentError('url must be a String or Uri. Got: ${url.runtimeType}');
  }

  static Uri _parseCleanUri(String raw) {
    final cleaned = _cleanUrlString(raw);
    return Uri.parse(cleaned);
  }

  static String _cleanUrlString(String raw) {
    final trimmed = raw.trim();
    return trimmed
        .replaceAll(RegExp(r'\s+([/?#&])'), r'$1')
        .replaceAll(RegExp(r'([/?#&])\s+'), r'$1');
  }

  static List<String> _splitPath(String path) {
    if (path.isEmpty) return const <String>[];
    return path.split('/').where((segment) => segment.trim().isNotEmpty).toList();
  }

  static Map<String, String>? _baseQueryOrNull(Uri base) {
    return base.queryParameters.isEmpty ? null : base.queryParameters;
  }

  static Map<String, String>? _stringifyQuery(
    Map<String, dynamic> queryParameters,
  ) {
    final cleaned = <String, String>{};
    for (final entry in queryParameters.entries) {
      final value = entry.value;
      if (value == null) continue;
      cleaned[entry.key] = value.toString();
    }
    return cleaned.isEmpty ? null : cleaned;
  }
}
