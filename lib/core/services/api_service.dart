import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cross/core/constants/api_constants.dart';
import 'package:cross/core/constants/api_endpoints.dart';
import 'package:cross/core/services/session_service.dart';
import 'package:flutter/foundation.dart';
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
	Future<bool>? _refreshFuture;

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
		String endpoint, Map<String, String> map, {
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

	Future<dynamic> patch(
		String endpoint, Map<String, dynamic> body, {
		bool authRequired = false,
		Map<String, String>? headers,
	}) {
		return _sendRequest(
			method: 'PATCH',
			endpoint: endpoint,
			body: body,
			authRequired: authRequired,
			headers: headers,
		);
	}

	Future<dynamic> put(
		String endpoint, {
		Map<String, dynamic>? body,
		bool authRequired = false,
		Map<String, String>? headers,
	}) {
		return _sendRequest(
			method: 'PUT',
			endpoint: endpoint,
			body: body,
			authRequired: authRequired,
			headers: headers,
		);
	}

	Future<dynamic> delete(
		String endpoint, {
		bool authRequired = false,
		Map<String, String>? headers,
	}) {
		return _sendRequest(
			method: 'DELETE',
			endpoint: endpoint,
			authRequired: authRequired,
			headers: headers,
		);
	}

	Future<dynamic> postMultipart(
		String endpoint, {
		Map<String, String>? fields,
		List<MapEntry<String, String>>? repeatedFields,
		List<http.MultipartFile>? files,
		bool authRequired = false,
		Map<String, String>? headers,
	}) async {
		final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
		final request = http.MultipartRequest('POST', uri);

		request.headers.addAll({
			'Accept': 'application/json',
			...?headers,
		});

		if (authRequired) {
			final accessToken = await _sessionService.getAccessToken();
			if (accessToken == null || accessToken.isEmpty) {
				throw const ApiException('Authentication required. Please log in.');
			}
			request.headers['Authorization'] = 'Bearer $accessToken';
		}

		if (fields != null) {
			request.fields.addAll(fields);
		}

		if (repeatedFields != null && repeatedFields.isNotEmpty) {
			request.fields.addEntries(repeatedFields);
		}

		if (files != null && files.isNotEmpty) {
			request.files.addAll(files);
		}

		_logMultipartDispatch(
			method: 'POST',
			endpoint: endpoint,
			request: request,
		);

		try {
			final streamedResponse = await _client
					.send(request)
					.timeout(const Duration(seconds: 60));
			final response = await http.Response.fromStream(streamedResponse);
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

	Future<dynamic> putMultipart(
		String endpoint, {
		Map<String, String>? fields,
		List<http.MultipartFile>? files,
		bool authRequired = false,
		Map<String, String>? headers,
	}) async {
		final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
		final request = http.MultipartRequest('PUT', uri);

		request.headers.addAll({
			'Accept': 'application/json',
			...?headers,
		});

		if (authRequired) {
			final accessToken = await _sessionService.getAccessToken();
			if (accessToken == null || accessToken.isEmpty) {
				throw const ApiException('Authentication required. Please log in.');
			}
			request.headers['Authorization'] = 'Bearer $accessToken';
		}

		if (fields != null) {
			request.fields.addAll(fields);
		}

		if (files != null && files.isNotEmpty) {
			request.files.addAll(files);
		}

		_logMultipartDispatch(
			method: 'PUT',
			endpoint: endpoint,
			request: request,
		);

		try {
			final streamedResponse = await _client
					.send(request)
					.timeout(const Duration(seconds: 60));
			final response = await http.Response.fromStream(streamedResponse);
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

	Future<dynamic> _sendRequest({
		required String method,
		required String endpoint,
		Map<String, dynamic>? body,
		bool authRequired = false,
		Map<String, String>? headers,
		bool allowAuthRetry = true,
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
				case 'PATCH':
					response = await _client
							.patch(
								uri,
								headers: requestHeaders,
								body: jsonEncode(body ?? <String, dynamic>{}),
							)
							.timeout(const Duration(seconds: 25));
					break;
				case 'PUT':
					response = await _client
							.put(
								uri,
								headers: requestHeaders,
								body: jsonEncode(body ?? <String, dynamic>{}),
							)
							.timeout(const Duration(seconds: 25));
					break;
				case 'DELETE':
					response = await _client
							.delete(uri, headers: requestHeaders)
							.timeout(const Duration(seconds: 25));
					break;
				default:
					throw ApiException('Unsupported HTTP method: $method');
			}

			if (response.statusCode == 401 &&
				authRequired &&
				allowAuthRetry &&
				endpoint != ApiEndpoints.refreshToken) {
				final refreshed = await _tryRefreshAndPersistTokens();
				if (refreshed) {
					return _sendRequest(
						method: method,
						endpoint: endpoint,
						body: body,
						authRequired: authRequired,
						headers: headers,
						allowAuthRetry: false,
					);
				}
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

	Future<bool> _tryRefreshAndPersistTokens() async {
		if (_refreshFuture != null) {
			return _refreshFuture!;
		}

		_refreshFuture = _performRefreshAndPersistTokens();
		try {
			return await _refreshFuture!;
		} finally {
			_refreshFuture = null;
		}
	}

	Future<bool> _performRefreshAndPersistTokens() async {
		final savedRefreshToken = await _sessionService.getRefreshToken();
		if (savedRefreshToken == null || savedRefreshToken.isEmpty) {
			await _sessionService.clearSession();
			return false;
		}

		try {
			final uri = Uri.parse('${ApiConstants.baseUrl}${ApiEndpoints.refreshToken}');
			final response = await _client
				.post(
					uri,
					headers: const {
						'Content-Type': 'application/json',
						'Accept': 'application/json',
					},
					body: jsonEncode({'refresh_token': savedRefreshToken}),
				)
				.timeout(const Duration(seconds: 25));

			if (response.statusCode < 200 || response.statusCode >= 300) {
				await _sessionService.clearSession();
				return false;
			}

			final parsedBody = _parseResponseBody(response.body);
			if (parsedBody is! Map<String, dynamic>) {
				await _sessionService.clearSession();
				return false;
			}

			final newAccessToken = _extractToken(
				parsedBody,
				snakeCaseKey: 'access_token',
				camelCaseKey: 'accessToken',
			);
			if (newAccessToken == null || newAccessToken.isEmpty) {
				await _sessionService.clearSession();
				return false;
			}

			final rotatedRefreshToken = _extractToken(
				parsedBody,
				snakeCaseKey: 'refresh_token',
				camelCaseKey: 'refreshToken',
			);
			final refreshToSave =
				(rotatedRefreshToken != null && rotatedRefreshToken.isNotEmpty)
					? rotatedRefreshToken
					: savedRefreshToken;

			await _sessionService.saveTokens(
				accessToken: newAccessToken,
				refreshToken: refreshToSave,
			);
			return true;
		} on SocketException {
			await _sessionService.clearSession();
			return false;
		} on TimeoutException {
			await _sessionService.clearSession();
			return false;
		} catch (_) {
			await _sessionService.clearSession();
			return false;
		}
	}

	String? _extractToken(
		Map<String, dynamic> body, {
		required String snakeCaseKey,
		required String camelCaseKey,
	}) {
		return body[snakeCaseKey]?.toString() ?? body[camelCaseKey]?.toString();
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

	void _logMultipartDispatch({
		required String method,
		required String endpoint,
		required http.MultipartRequest request,
	}) {
		if (!kDebugMode) return;
		if (endpoint != ApiEndpoints.tracks) return;

		final timestamp = DateTime.now().toIso8601String();
		debugPrint(
			'[UploadTrace][$timestamp][multipart.dispatch] '
			'$method $endpoint fields=${request.fields} '
			'files=${request.files.map((f) => '${f.field}:${f.filename ?? 'unknown'}(length=${f.length})').toList()}',
		);
	}
}
