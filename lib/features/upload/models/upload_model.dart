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
		this.artworkBytes,
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
	// Local/UI-only image bytes for previews; never sent to or read from backend JSON.
	final Uint8List? artworkBytes;

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
		Uint8List? artworkBytes,
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
			artworkBytes: artworkBytes ?? this.artworkBytes,
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
			// artworkBytes intentionally excluded from JSON serialization.
		};
	}

	static String _resolveTrackId(Map<String, dynamic> json) {
		final mongoId = json['_id']?.toString().trim();
		if (mongoId != null && mongoId.isNotEmpty) return mongoId;

		final genericId = json['id']?.toString().trim();
		if (genericId != null && genericId.isNotEmpty) return genericId;

		return '';
	}

	static UploadTrackStatus _statusFromJson(String? value) {
		switch (value) {
			case 'processing':
				return UploadTrackStatus.processing;
			case 'finished':
				return UploadTrackStatus.finished;
			case 'failed':
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
