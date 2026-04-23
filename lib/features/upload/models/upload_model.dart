import 'dart:typed_data';

enum UploadTrackStatus {
	draft,
	processing,
	finished,
	failed,
}

enum UploadTrackPrivacy {
	public,
	private,
}

class UploadModel {
	const UploadModel({
		required this.id,
		required this.title,
		required this.artistName,
		required this.collaborators,
		required this.genre,
		required this.description,
		required this.tags,
		required this.privacy,
		required this.artworkPathOrUrl,
		required this.audioPathOrFileName,
		required this.status,
		required this.releaseDate,
		this.waveformPeaks,
		this.waveformSamples,
		this.progressPercent,
		this.processingErrorMessage,
		this.isHidden = false,
		this.artworkBytes,
		this.previewStartSeconds,
	});

	final String id;
	final String title;
	final String artistName;
	final List<String> collaborators;
	final String genre;
	final String description;
	final List<String> tags;
	final String privacy;
	final String artworkPathOrUrl;
	final String audioPathOrFileName;
	final UploadTrackStatus status;
	final DateTime releaseDate;
	final List<double>? waveformPeaks;
	final int? waveformSamples;
	final double? progressPercent;
	final String? processingErrorMessage;
	final bool isHidden;
	// Local/UI-only image bytes for previews; never sent to or read from backend JSON.
	final Uint8List? artworkBytes;
	final int? previewStartSeconds;

	UploadTrackPrivacy get privacyValue => _privacyFromJson(privacy);

	UploadModel copyWith({
		String? id,
		String? title,
		String? artistName,
		List<String>? collaborators,
		String? genre,
		String? description,
		List<String>? tags,
		String? privacy,
		String? artworkPathOrUrl,
		String? audioPathOrFileName,
		UploadTrackStatus? status,
		DateTime? releaseDate,
		List<double>? waveformPeaks,
		int? waveformSamples,
		double? progressPercent,
		String? processingErrorMessage,
		bool? isHidden,
		Uint8List? artworkBytes,
		int? previewStartSeconds,
	}) {
		return UploadModel(
			id: id ?? this.id,
			title: title ?? this.title,
			artistName: artistName ?? this.artistName,
			collaborators: collaborators ?? this.collaborators,
			genre: genre ?? this.genre,
			description: description ?? this.description,
			tags: tags ?? this.tags,
			privacy: privacy ?? this.privacy,
			artworkPathOrUrl: artworkPathOrUrl ?? this.artworkPathOrUrl,
			audioPathOrFileName: audioPathOrFileName ?? this.audioPathOrFileName,
			status: status ?? this.status,
			releaseDate: releaseDate ?? this.releaseDate,
			waveformPeaks: waveformPeaks ?? this.waveformPeaks,
			waveformSamples: waveformSamples ?? this.waveformSamples,
			progressPercent: progressPercent ?? this.progressPercent,
			processingErrorMessage:
					processingErrorMessage ?? this.processingErrorMessage,
			isHidden: isHidden ?? this.isHidden,
			artworkBytes: artworkBytes ?? this.artworkBytes,
			previewStartSeconds: previewStartSeconds ?? this.previewStartSeconds,
		);
	}

	factory UploadModel.fromJson(Map<String, dynamic> json) {
		final resolvedId = _resolveTrackId(json);
		final tagsFromJson = json['tags'];
		final parsedTags = tagsFromJson is List
				? tagsFromJson.map((item) => item.toString()).toList()
				: tagsFromJson == null
						? <String>[]
						: tagsFromJson
								.toString()
								.split(',')
								.map((item) => item.trim())
								.where((item) => item.isNotEmpty)
								.toList();

		final normalizedPrivacy =
				_privacyFromJson(
						json['visibility']?.toString() ?? json['privacy']?.toString(),
				)
				.name;

		return UploadModel(
			id: resolvedId,
			title: json['title']?.toString() ?? '',
			artistName: json['artistName']?.toString() ??
					json['artist_id']?.toString() ??
					'',
			collaborators: (json['collaborators'] as List<dynamic>? ?? const [])
					.map((item) => item.toString())
					.toList(),
			genre: json['genre']?.toString() ?? '',
			description: json['description']?.toString() ?? '',
			tags: parsedTags,
			privacy: normalizedPrivacy,
			artworkPathOrUrl:
					json['artwork_url']?.toString() ?? json['artworkPathOrUrl']?.toString() ?? '',
			audioPathOrFileName:
					json['audio_url']?.toString() ?? json['audioPathOrFileName']?.toString() ?? '',
			status: _statusFromJson(json['status']?.toString()),
			// Fallback for responses that do not include a parseable created/release date.
			releaseDate: DateTime.tryParse(
						json['releaseDate']?.toString() ?? json['createdAt']?.toString() ?? '',
				) ??
					DateTime.now(),
			waveformPeaks: (json['peaks'] as List<dynamic>? ??
							json['waveformPeaks'] as List<dynamic>?)
					?.map((item) => (item as num).toDouble())
					.toList(),
			waveformSamples: _tryParseInt(json['samples'] ?? json['waveformSamples']),
			progressPercent: _tryParseProgress(
					json['progress_percent'] ?? json['progressPercent'],
			),
			processingErrorMessage:
					json['error_message']?.toString() ?? json['errorMessage']?.toString(),
			isHidden: (json['is_hidden'] == true) ||
						(json['isHidden'] == true),
			previewStartSeconds: _tryParseInt(
				json['preview_start_seconds'] ?? json['previewStartSeconds'],
			),
			// Intentionally omitted from JSON (local in-memory UI state only).
			artworkBytes: null,
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'id': id,
			'title': title,
			'artistName': artistName,
			'collaborators': collaborators,
			'genre': genre,
			'description': description,
			'tags': tags,
			'privacy': privacy,
			'artworkPathOrUrl': artworkPathOrUrl,
			'audioPathOrFileName': audioPathOrFileName,
			'status': status.name,
			'releaseDate': releaseDate.toIso8601String(),
			'waveformPeaks': waveformPeaks,
			'waveformSamples': waveformSamples,
			'progressPercent': progressPercent,
			'processingErrorMessage': processingErrorMessage,
			'isHidden': isHidden,
			'previewStartSeconds': previewStartSeconds,
			// artworkBytes intentionally excluded from JSON serialization.
		};
	}

	static String _resolveTrackId(Map<String, dynamic> json) {
		final candidates = [
			json['_id'],
			json['track_id'],
			json['trackId'],
			json['id'],
		];

		for (final candidate in candidates) {
			final normalized = _normalizeId(candidate);
			if (normalized.isNotEmpty) return normalized;
		}

		return '';
	}

	static String _normalizeId(dynamic value) {
		if (value == null) return '';

		if (value is int) return value.toString();

		if (value is num) {
			final normalizedInt = value.toInt();
			if (value == normalizedInt) return normalizedInt.toString();
			return '';
		}

		final asString = value.toString().trim();
		if (asString.isEmpty) return '';

		final numeric = num.tryParse(asString);
		if (numeric != null) {
			final normalizedInt = numeric.toInt();
			if (numeric == normalizedInt) {
				return normalizedInt.toString();
			}
			return '';
		}

		return asString;
	}

	static UploadTrackStatus _statusFromJson(String? value) {
		final normalized = value?.trim().toLowerCase() ?? '';

		switch (normalized) {
			case 'processing':
			case 'queued':
			case 'pending':
			case 'in_progress':
			case 'in-progress':
				return UploadTrackStatus.processing;
			case 'finished':
			case 'complete':
			case 'completed':
			case 'ready':
			case 'success':
				return UploadTrackStatus.finished;
			case 'failed':
			case 'error':
				return UploadTrackStatus.failed;
			case 'draft':
			default:
				return UploadTrackStatus.draft;
		}
	}

	static UploadTrackStatus statusFromApi(String? value) {
		return _statusFromJson(value);
	}

	static double? _tryParseProgress(dynamic value) {
		if (value is num) return value.toDouble();
		if (value == null) return null;
		return double.tryParse(value.toString());
	}

	static int? _tryParseInt(dynamic value) {
		if (value is int) return value;
		if (value is num) return value.toInt();
		if (value == null) return null;
		return int.tryParse(value.toString());
	}

	static UploadTrackPrivacy _privacyFromJson(String? value) {
		switch (value?.toLowerCase()) {
			case 'private':
				return UploadTrackPrivacy.private;
			case 'public':
			default:
				return UploadTrackPrivacy.public;
		}
	}
}
