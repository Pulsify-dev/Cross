import 'package:cross/core/constants/api_endpoints.dart';
import 'package:cross/core/services/api_service.dart';
import 'package:cross/features/upload/models/upload_model.dart';
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
		final response = await _apiService.postMultipart(
			ApiEndpoints.tracks,
			fields: body,
			repeatedFields: repeatedTags,
			files: files,
			authRequired: true,
		);

		if (response is! Map<String, dynamic>) {
			throw const ApiException('Invalid create track response.');
		}

		final created = UploadModel.fromJson(response).copyWith(
			collaborators: track.collaborators,
			releaseDate: track.releaseDate,
			artworkBytes: track.artworkBytes,
		);

		if (created.id.trim().isEmpty) {
			throw const ApiException('Create track response is missing track id.');
		}

		_mockTracksById[created.id] = created;
		return created;
	}

	Future<UploadTrackStatusResult> getTrackStatus(String trackId) async {
		final response = await _apiService.get(
			ApiEndpoints.trackStatus(trackId),
			authRequired: true,
		);

		if (response is! Map<String, dynamic>) {
			throw const ApiException('Invalid track status response.');
		}

		final status = UploadModel.statusFromApi(response['status']?.toString());
		final progressRaw = response['progress_percent'] ?? response['progressPercent'];
		final progressPercent = progressRaw is num
				? progressRaw.toDouble()
				: double.tryParse(progressRaw?.toString() ?? '');

		return UploadTrackStatusResult(
			status: status,
			progressPercent: progressPercent,
			errorMessage: response['error_message']?.toString(),
		);
	}

	Future<List<double>> getWaveform(String trackId) async {
		if (trackId.trim().isEmpty) {
			throw const ApiException('Track id is required to fetch waveform.');
		}

		final response = await _apiService.get(
			ApiEndpoints.trackWaveform(trackId),
			authRequired: false,
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

		final track = UploadModel.fromJson(response);
		if (track.id.trim().isEmpty) {
			throw const ApiException('Track response is missing track id.');
		}

		_mockTracksById[track.id] = track;
		if (track.id != trackId) {
			_mockTracksById[trackId] = track;
		}

		return track;
	}

	Future<UploadModel?> updateTrackMetadata({
		required String trackId,
		String? title,
		String? genre,
		String? description,
		List<String>? tags,
		String? privacy,
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

		if (body.isEmpty) {
			throw const ApiException('No valid metadata fields to update.');
		}

		final response = await _apiService.patch(
			ApiEndpoints.trackMetadata(trackId),
			body: body,
			authRequired: true,
		);

		if (response is! Map<String, dynamic>) {
			throw const ApiException('Invalid update track metadata response.');
		}

		final mapped = UploadModel.fromJson(response);
		final hasArtworkInResponse =
				response.containsKey('artwork_url') || response.containsKey('artworkUrl');
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
}
