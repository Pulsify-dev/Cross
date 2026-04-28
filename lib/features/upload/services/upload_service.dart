import 'package:cross/core/constants/api_endpoints.dart';
import 'package:cross/core/services/api_service.dart';
import 'package:cross/features/upload/models/upload_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class UploadTrackStatusResult {
	const UploadTrackStatusResult({
		required this.status,
		required this.progressPercent,
		this.errorMessage,
	});

	final UploadTrackStatus status;
	final double? progressPercent;
	final String? errorMessage;
}

class UploadArtistTracksPage {
	const UploadArtistTracksPage({
		required this.tracks,
		required this.total,
		required this.page,
		required this.limit,
	});

	final List<UploadModel> tracks;
	final int total;
	final int page;
	final int limit;

	bool get hasMore => (page * limit) < total;
}

class UploadService {
	UploadService({ApiService? apiService})
			: _apiService = apiService ?? ApiService();

	final ApiService _apiService;

	// Local in-memory cache to keep provider state in sync with recent backend updates.
	final Map<String, UploadModel> _mockTracksById = {};

	Future<UploadModel> createTrack(UploadModel track) async {
		final audioPath = track.audioPathOrFileName;
		if (audioPath.isEmpty) {
			throw const ApiException('Audio file is required.');
		}

		final files = <http.MultipartFile>[
			await http.MultipartFile.fromPath(
				'audio_file',
				audioPath,
				contentType: _inferMediaTypeFromPath(audioPath, isAudio: true),
			),
		];

		if (track.artworkPathOrUrl.isNotEmpty) {
			files.add(
				await http.MultipartFile.fromPath(
					'artwork_file',
					track.artworkPathOrUrl,
					contentType: _inferMediaTypeFromPath(
						track.artworkPathOrUrl,
						isAudio: false,
					),
				),
			);
		} else if (track.artworkBytes != null) {
			files.add(
				http.MultipartFile.fromBytes(
					'artwork_file',
					track.artworkBytes!,
					filename: 'cover.jpg',
					contentType: _inferMediaTypeFromPath('cover.jpg', isAudio: false),
				),
			);
		} else {
			throw const ApiException('Cover image is required.');
		}

		final repeatedTags = track.tags
				.map((tag) => tag.trim())
				.where((tag) => tag.isNotEmpty)
				.map((tag) => MapEntry('tags', tag))
				.toList();
		final body = <String, String>{
			'title': track.title,
			'genre': track.genre,
		};

		if (track.description.trim().isNotEmpty) {
			body['description'] = track.description.trim();
		}

		if (track.previewStartSeconds != null) {
			body['preview_start_seconds'] = track.previewStartSeconds.toString();
		}

		if (track.lyrics != null && track.lyrics!.trim().isNotEmpty) {
			body['lyrics'] = track.lyrics!.trim();
		}

		_logCreateTrackRequest(
			track: track,
			fields: body,
			repeatedFields: repeatedTags,
			files: files,
		);
		_logUploadTrace(
			'step1.beforeCreate',
			'POST ${ApiEndpoints.tracks} started',
		);

		dynamic response;
		try {
			response = await _apiService.postMultipart(
				ApiEndpoints.tracks,
				fields: body,
				repeatedFields: repeatedTags,
				files: files,
				authRequired: true,
			);
		} on ApiException catch (error) {
			_logUploadTrace(
				'step2.afterCreate',
				'POST ${ApiEndpoints.tracks} failed status=${error.statusCode ?? 'unknown'} body=${error.message}',
			);
			rethrow;
		}

		if (response is! Map<String, dynamic>) {
			throw const ApiException('Invalid create track response.');
		}

		final payload = _extractTrackPayload(response);
		final created = UploadModel.fromJson(payload).copyWith(
			collaborators: track.collaborators,
			releaseDate: track.releaseDate,
			artworkBytes: track.artworkBytes,
		);

		_logUploadTrace(
			'step2.afterCreate',
			'POST ${ApiEndpoints.tracks} success status=${_responseStatusCodeSummary(response, fallback: '2xx')} body=${_summarizeBody(response)} parsedTrackId=${created.id}',
		);

		if (created.id.trim().isEmpty) {
			throw const ApiException('Create track response is missing track id.');
		}

		_mockTracksById[created.id] = created;
		return created;
	}

	Future<UploadTrackStatusResult> getTrackStatus(String trackId) async {
		final endpoint = ApiEndpoints.trackStatus(trackId);
		_logUploadTrace('step3.beforeStatusPoll', 'GET $endpoint started');

		dynamic response;
		try {
			response = await _apiService.get(
				endpoint,
				authRequired: true,
			);
		} on ApiException catch (error) {
			_logUploadTrace(
				'step4.afterStatusPoll',
				'GET $endpoint failed status=${error.statusCode ?? 'unknown'} body=${error.message}',
			);
			rethrow;
		}

		if (response is! Map<String, dynamic>) {
			throw const ApiException('Invalid track status response.');
		}

		final statusPayload = _extractStatusPayload(response);
		final status = UploadModel.statusFromApi(
			statusPayload['status']?.toString(),
		);
		final progressRaw =
				statusPayload['progress_percent'] ?? statusPayload['progressPercent'];
		final progressPercent = progressRaw is num
				? progressRaw.toDouble()
				: double.tryParse(progressRaw?.toString() ?? '');

		_logUploadTrace(
			'step4.afterStatusPoll',
			'GET $endpoint success status=${_responseStatusCodeSummary(response, fallback: '2xx')} body=${_summarizeBody(response)} parsedStatus=${status.name}',
		);

		return UploadTrackStatusResult(
			status: status,
			progressPercent: progressPercent,
			errorMessage: statusPayload['error_message']?.toString(),
		);
	}

	Future<List<double>> getWaveform(String trackId) async {
		if (trackId.trim().isEmpty) {
			throw const ApiException('Track id is required to fetch waveform.');
		}

		final endpoint = ApiEndpoints.trackWaveform(trackId);
		_logUploadTrace('step5.beforeWaveform', 'GET $endpoint started');

		dynamic response;
		try {
			response = await _apiService.get(
				endpoint,
				authRequired: true,
			);
		} on ApiException catch (error) {
			_logUploadTrace(
				'step6.afterWaveform',
				'GET $endpoint failed status=${error.statusCode ?? 'unknown'} body=${error.message}',
			);
			rethrow;
		}

		_logUploadTrace(
			'step6.afterWaveform',
			'GET $endpoint success status=${_responseStatusCodeSummary(response, fallback: '2xx')} body=${_summarizeBody(response)}',
		);

		final peaks = _extractWaveformPeaks(response);
		if (peaks.isEmpty) {
			throw const ApiException('Waveform response is missing peaks.');
		}

		final existing = _mockTracksById[trackId];
		if (existing != null) {
			_mockTracksById[trackId] = existing.copyWith(waveformPeaks: peaks);
		}

		return peaks;
	}

	Future<UploadModel?> getTrackById(String trackId) async {
		if (trackId.trim().isEmpty) {
			throw const ApiException('Track id is required.');
		}

		final response = await _apiService.get(
			ApiEndpoints.trackById(trackId),
			authRequired: false,
		);

		if (response is! Map<String, dynamic>) {
			throw const ApiException('Invalid track response.');
		}

		final payload = _extractTrackPayload(response);
		final track = UploadModel.fromJson(payload);
		if (track.id.trim().isEmpty) {
			throw const ApiException('Track response is missing track id.');
		}

		_mockTracksById[track.id] = track;
		if (track.id != trackId) {
			_mockTracksById[trackId] = track;
		}

		return track;
	}

	Future<String?> getTrackLyrics(String trackId) async {
		if (trackId.trim().isEmpty) {
			throw const ApiException('Track id is required.');
		}

		final response = await _apiService.get(
			ApiEndpoints.trackLyrics(trackId),
			authRequired: true,
		);

		if (response is! Map<String, dynamic>) return null;
		return response['lyrics']?.toString();
	}

	Future<UploadModel?> updateTrackMetadata({
		required String trackId,
		String? title,
		String? genre,
		String? description,
		List<String>? tags,
		String? privacy,
		int? previewStartSeconds,
		String? lyrics,
	}) async {
		if (trackId.trim().isEmpty) {
			throw const ApiException('Track id is required for metadata update.');
		}

		final body = <String, dynamic>{};
		if (title != null) body['title'] = title;
		if (genre != null) body['genre'] = genre;
		if (description != null) body['description'] = description;
		if (tags != null) body['tags'] = tags;
		if (privacy != null) body['visibility'] = privacy;
		if (previewStartSeconds != null) body['preview_start_seconds'] = previewStartSeconds;
		if (lyrics != null) body['lyrics'] = lyrics;

		if (body.isEmpty) {
			throw const ApiException('No valid metadata fields to update.');
		}

		final response = await _apiService.patch(
			ApiEndpoints.trackMetadata(trackId),
			 body,
			authRequired: true,
		);

		if (response is! Map<String, dynamic>) {
			throw const ApiException('Invalid update track metadata response.');
		}

		final payload = _extractTrackPayload(response);
		final mapped = UploadModel.fromJson(payload);
		final hasArtworkInResponse =
				payload.containsKey('artwork_url') || payload.containsKey('artworkUrl');
		final mappedArtworkPath = mapped.artworkPathOrUrl.trim();
		final existing = _mockTracksById[trackId];

		final merged = existing == null
				? mapped.copyWith(id: mapped.id.isNotEmpty ? mapped.id : trackId)
				: existing.copyWith(
						id: mapped.id.isNotEmpty ? mapped.id : existing.id,
						title: mapped.title.isNotEmpty ? mapped.title : existing.title,
						genre: mapped.genre.isNotEmpty ? mapped.genre : existing.genre,
						description: mapped.description,
						tags: mapped.tags,
						privacy: mapped.privacy,
						artworkPathOrUrl: hasArtworkInResponse
								? (mappedArtworkPath.isNotEmpty
										? mappedArtworkPath
										: existing.artworkPathOrUrl)
								: existing.artworkPathOrUrl,
						artworkBytes: hasArtworkInResponse ? null : existing.artworkBytes,
						status: mapped.status,
						progressPercent: mapped.progressPercent,
						processingErrorMessage: mapped.processingErrorMessage,
						previewStartSeconds: mapped.previewStartSeconds ?? existing.previewStartSeconds,
				);

		_mockTracksById[trackId] = merged;
		if (mapped.id.isNotEmpty && mapped.id != trackId) {
			_mockTracksById[mapped.id] = merged;
		}
		return merged;
	}

	Future<UploadModel?> updateTrackArtwork({
		required String trackId,
		required String artworkPathOrUrl,
	}) async {
		if (trackId.trim().isEmpty) {
			throw const ApiException('Track id is required for artwork update.');
		}

		if (artworkPathOrUrl.trim().isEmpty) {
			throw const ApiException('Artwork file is required.');
		}

		final response = await _apiService.putMultipart(
			ApiEndpoints.trackArtwork(trackId),
			files: [
				await http.MultipartFile.fromPath(
					'file',
					artworkPathOrUrl,
					contentType: _inferMediaTypeFromPath(
						artworkPathOrUrl,
						isAudio: false,
					),
				),
			],
			authRequired: true,
		);

		if (response is! Map<String, dynamic>) {
			throw const ApiException('Invalid update artwork response.');
		}

		final artworkUrl =
				response['artwork_url']?.toString() ?? response['artworkUrl']?.toString();
		if (artworkUrl == null || artworkUrl.trim().isEmpty) {
			throw const ApiException('Update artwork response is missing artwork url.');
		}

		final track = _mockTracksById[trackId];
		if (track == null) {
			throw const ApiException('Track not found locally for artwork sync.');
		}

		final updated = track.copyWith(
			artworkPathOrUrl: artworkUrl,
			artworkBytes: null,
		);
		_mockTracksById[trackId] = updated;
		return updated;
	}

	Future<bool> deleteTrack(String trackId) async {
		if (trackId.trim().isEmpty) {
			throw const ApiException('Track id is required for deletion.');
		}

		await _apiService.delete(
			ApiEndpoints.trackDelete(trackId),
			authRequired: true,
		);

		// Keep local store in sync for not-yet-integrated feature paths.
		_mockTracksById.remove(trackId);
		return true;
	}

	Future<UploadArtistTracksPage> getArtistTracks({
		required String artistId,
		int page = 1,
		int limit = 20,
	}) async {
		if (artistId.trim().isEmpty) {
			throw const ApiException('Artist id is required to fetch artist tracks.');
		}

		final endpoint = ApiEndpoints.artistTracks(
			artistId,
			page: page,
			limit: limit,
		);

		final response = await _apiService.get(endpoint, authRequired: true);
		final parsed = _parseArtistTracksPayload(
			response,
			fallbackPage: page,
			fallbackLimit: limit,
		);

		for (final track in parsed.tracks) {
			if (track.id.trim().isEmpty) continue;
			_mockTracksById[track.id] = track;
		}

		return parsed;
	}

	List<double> _extractWaveformPeaks(dynamic response) {
		if (response is List) {
			return response
					.map((item) => item is num ? item.toDouble() : null)
					.whereType<double>()
					.toList();
		}

		if (response is Map<String, dynamic>) {
			final candidates = <dynamic>[
				response['peaks'],
				response['waveform'],
				response['data'] is Map<String, dynamic>
						? (response['data'] as Map<String, dynamic>)['peaks']
						: null,
				response['waveform'] is Map<String, dynamic>
						? (response['waveform'] as Map<String, dynamic>)['peaks']
						: null,
			];

			for (final candidate in candidates) {
				if (candidate is List) {
					final parsed = candidate
							.map((item) => item is num ? item.toDouble() : null)
							.whereType<double>()
							.toList();
					if (parsed.isNotEmpty) return parsed;
				}
			}
		}

		return const <double>[];
	}

	UploadArtistTracksPage _parseArtistTracksPayload(
		dynamic response, {
		required int fallbackPage,
		required int fallbackLimit,
	}) {
		List<dynamic> rawTracks = const <dynamic>[];
		var total = 0;
		var page = fallbackPage;
		var limit = fallbackLimit;

		if (response is List) {
			rawTracks = response;
			total = response.length;
		} else if (response is Map<String, dynamic>) {
			final candidates = <dynamic>[
				response['tracks'],
				response['data'] is Map<String, dynamic>
						? (response['data'] as Map<String, dynamic>)['tracks']
						: null,
			];

			for (final candidate in candidates) {
				if (candidate is List) {
					rawTracks = candidate;
					break;
				}
			}

			total = _tryParseInt(response['total']) ?? rawTracks.length;
			page = _tryParseInt(response['page']) ?? fallbackPage;
			limit = _tryParseInt(response['limit']) ?? fallbackLimit;
		} else {
			throw const ApiException('Invalid artist tracks response.');
		}

		final tracks = rawTracks
				.whereType<Map<String, dynamic>>()
				.map(UploadModel.fromJson)
				.where((track) => track.id.trim().isNotEmpty)
				.toList();

		return UploadArtistTracksPage(
			tracks: tracks,
			total: total,
			page: page,
			limit: limit,
		);
	}

	MediaType? _inferMediaTypeFromPath(String path, {required bool isAudio}) {
		final trimmedPath = path.trim();
		if (trimmedPath.isEmpty) return null;

		final dotIndex = trimmedPath.lastIndexOf('.');
		if (dotIndex < 0 || dotIndex == trimmedPath.length - 1) return null;

		final ext = trimmedPath.substring(dotIndex + 1).toLowerCase();

		if (isAudio) {
			switch (ext) {
				case 'mp3':
					return MediaType('audio', 'mpeg');
				case 'wav':
					return MediaType('audio', 'wav');
				case 'flac':
					return MediaType('audio', 'flac');
				case 'aac':
					return MediaType('audio', 'aac');
				default:
					return null;
			}
		}

		switch (ext) {
			case 'jpg':
			case 'jpeg':
				return MediaType('image', 'jpeg');
			case 'png':
				return MediaType('image', 'png');
			case 'webp':
				return MediaType('image', 'webp');
			default:
				return null;
		}
	}

	int? _tryParseInt(dynamic value) {
		if (value is int) return value;
		if (value is num) return value.toInt();
		if (value == null) return null;
		return int.tryParse(value.toString());
	}

	Map<String, dynamic> _extractTrackPayload(Map<String, dynamic> response) {
		final directData = response['data'];

		if (directData is Map<String, dynamic>) {
			final nestedTrack = directData['track'];
			if (nestedTrack is Map<String, dynamic> &&
					_hasUsableTrackId(nestedTrack)) {
				return nestedTrack;
			}

			if (_looksLikeTrackPayload(directData) && _hasUsableTrackId(directData)) {
				return directData;
			}
		}

		final discovered = _findLikelyTrackPayload(response);
		if (discovered != null) {
			return discovered;
		}

		return response;
	}

	Map<String, dynamic> _extractStatusPayload(Map<String, dynamic> response) {
		if (response.containsKey('status') ||
				response.containsKey('progress_percent') ||
				response.containsKey('progressPercent')) {
			return response;
		}

		final data = response['data'];
		if (data is Map<String, dynamic>) {
			return data;
		}

		return response;
	}

	bool _looksLikeTrackPayload(Map<String, dynamic> payload) {
		return payload.containsKey('_id') ||
				payload.containsKey('track_id') ||
				payload.containsKey('audio_url') ||
				payload.containsKey('title');
	}

	Map<String, dynamic>? _findLikelyTrackPayload(dynamic node) {
		if (node is! Map<String, dynamic>) return null;

		if (_looksLikeTrackPayload(node) && _hasUsableTrackId(node)) {
			return node;
		}

		for (final value in node.values) {
			if (value is Map<String, dynamic>) {
				final found = _findLikelyTrackPayload(value);
				if (found != null) return found;
			}
		}

		return null;
	}

	bool _hasUsableTrackId(Map<String, dynamic> payload) {
		final candidates = [
			payload['_id'],
			payload['track_id'],
			payload['trackId'],
			payload['id'],
		];

		for (final candidate in candidates) {
			if (_isUsableTrackIdValue(candidate)) return true;
		}

		return false;
	}

	bool _isUsableTrackIdValue(dynamic value) {
		if (value == null) return false;
		if (value is int) return true;

		if (value is num) {
			return value == value.toInt();
		}

		final asString = value.toString().trim();
		if (asString.isEmpty) return false;

		final parsedNumeric = num.tryParse(asString);
		if (parsedNumeric == null) return true;
		return parsedNumeric == parsedNumeric.toInt();
	}

	String _responseStatusCodeSummary(
		Map<String, dynamic> response, {
		required String fallback,
	}) {
		final candidates = [
			response['statusCode'],
			response['status_code'],
			response['code'],
		];

		for (final candidate in candidates) {
			if (candidate is int) return candidate.toString();
			final parsed = int.tryParse(candidate?.toString() ?? '');
			if (parsed != null) return parsed.toString();
		}

		return fallback;
	}

	String _summarizeBody(dynamic body) {
		if (body is Map<String, dynamic>) {
			final keys = body.keys.take(8).join(',');
			final message =
					body['message']?.toString() ?? body['error']?.toString() ?? '';
			var status = body['status']?.toString() ?? '';
			if (status.isEmpty) {
				final nested = body['data'];
				if (nested is Map<String, dynamic>) {
					status = nested['status']?.toString() ?? '';
				}
			}
			return 'keys=[$keys] message=${message.isEmpty ? '-' : message} status=${status.isEmpty ? '-' : status}';
		}

		if (body is List) {
			return 'list(size=${body.length})';
		}

		return body.toString();
	}

	void _logUploadTrace(String step, String message) {
		if (!kDebugMode) return;
		final timestamp = DateTime.now().toIso8601String();
		debugPrint('[UploadTrace][$timestamp][$step] $message');
	}

	void _logCreateTrackRequest({
		required UploadModel track,
		required Map<String, String> fields,
		required List<MapEntry<String, String>> repeatedFields,
		required List<http.MultipartFile> files,
	}) {
		if (!kDebugMode) return;

		final numericMetadataCandidates = <String, dynamic>{
			'waveformSamples': track.waveformSamples,
			'progressPercent': track.progressPercent,
		};

		final sentFieldKeys = [
			...fields.keys,
			...repeatedFields.map((entry) => entry.key),
		];

		debugPrint(
			'[UploadService.createTrack] Sending multipart request with '
			'fields=$fields, repeatedFields=${repeatedFields.map((e) => '${e.key}:${e.value}').toList()}, '
			'files=${files.map((file) => '${file.field}:${file.filename ?? 'unknown'}(length=${file.length})').toList()}, '
			'numericCandidates=$numericMetadataCandidates, '
			'numericFieldKeysSent=${sentFieldKeys.where((key) => key.contains('duration') || key.contains('bitrate') || key.contains('size') || key.contains('sample') || key.contains('progress')).toList()}',
		);
	}
}
