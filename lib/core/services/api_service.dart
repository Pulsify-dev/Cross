import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cross/core/constants/api_constants.dart';
import 'package:cross/core/services/session_service.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
	final String message;
	final int? statusCode;

	const ApiException(this.message, {this.statusCode});

	@override
	String toString() {
		return statusCode == null ? message : '[$statusCode] $message';
	}
}

class ApiService {
	ApiService({http.Client? client, SessionService? sessionService})
			: _client = client ?? http.Client(),
				_sessionService = sessionService ?? SessionService();

	final http.Client _client;
	final SessionService _sessionService;

	Future<dynamic> get(
		String endpoint, {
		bool authRequired = false,
		Map<String, String>? headers,
	}) {
		return _sendRequest(
			method: 'GET',
			endpoint: endpoint,
			authRequired: authRequired,
			headers: headers,
		);
	}

	Future<dynamic> post(
		String endpoint, {
		Map<String, dynamic>? body,
		bool authRequired = false,
		Map<String, String>? headers,
	}) {
		return _sendRequest(
			method: 'POST',
			endpoint: endpoint,
			body: body,
			authRequired: authRequired,
			headers: headers,
		);
	}

	Future<dynamic> _sendRequest({
		required String method,
		required String endpoint,
		Map<String, dynamic>? body,
		bool authRequired = false,
		Map<String, String>? headers,
	}) async {
		final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
		final requestHeaders = <String, String>{
			'Content-Type': 'application/json',
			'Accept': 'application/json',
			...?headers,
		};

		if (authRequired) {
			final accessToken = await _sessionService.getAccessToken();
			if (accessToken == null || accessToken.isEmpty) {
				throw const ApiException('Authentication required. Please log in.');
			}
			requestHeaders['Authorization'] = 'Bearer $accessToken';
		}

		try {
			late final http.Response response;

			switch (method) {
				case 'GET':
					response = await _client
							.get(uri, headers: requestHeaders)
							.timeout(const Duration(seconds: 25));
					break;
				case 'POST':
					response = await _client
							.post(
								uri,
								headers: requestHeaders,
								body: jsonEncode(body ?? <String, dynamic>{}),
							)
							.timeout(const Duration(seconds: 25));
					break;
				default:
					throw ApiException('Unsupported HTTP method: $method');
			}

			final parsedBody = _parseResponseBody(response.body);
			if (response.statusCode >= 200 && response.statusCode < 300) {
				return parsedBody;
			}

			throw ApiException(
				_extractErrorMessage(parsedBody),
				statusCode: response.statusCode,
			);
		} on SocketException {
			throw const ApiException('No internet connection. Please try again.');
		} on TimeoutException {
			throw const ApiException('Request timed out. Please try again.');
		}
	}

	dynamic _parseResponseBody(String body) {
		if (body.trim().isEmpty) {
			return <String, dynamic>{};
		}

		try {
			return jsonDecode(body);
		} catch (_) {
			return <String, dynamic>{'message': body};
		}
	}

	String _extractErrorMessage(dynamic body) {
		if (body is Map<String, dynamic>) {
			final candidate = body['message'] ?? body['error'] ?? body['detail'];
			if (candidate != null && candidate.toString().trim().isNotEmpty) {
				return candidate.toString();
			}
		}

		return 'Something went wrong. Please try again.';
	}
}
