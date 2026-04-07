import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:cross/core/services/api_service.dart';
import 'package:cross/features/upload/models/upload_model.dart';
import 'package:cross/features/upload/services/upload_service.dart';

class UploadProvider extends ChangeNotifier {
	UploadProvider({UploadService? uploadService})
			: _uploadService = uploadService ?? UploadService();

	final UploadService _uploadService;

	List<UploadModel> _uploadedTracks = [];
	bool _isLoading = false;
	bool _isUploading = false;
	String? _errorMessage;
	String? _successMessage;
	String? _currentOperation;
	UploadTrackStatus? _selectedStatus;
	final Map<String, Timer> _statusPollTimersByTrackId = {};
	final Set<String> _statusPollRequestsInFlight = {};
	final Set<String> _waveformRequestsInFlight = {};
	final Map<String, String> _waveformErrorsByTrackId = {};
	final Map<String, List<UploadModel>> _publicArtistTracksByUserId = {};
	final Map<String, int> _publicArtistLastPageByUserId = {};
	final Map<String, int> _publicArtistTotalByUserId = {};
	final Map<String, bool> _publicArtistHasMoreByUserId = {};
	String? _loadedArtistId;
	int _lastLoadedArtistTracksPage = 1;
	int _artistTracksTotal = 0;
	bool _hasMoreArtistTracks = false;
	final Duration _statusPollInterval = const Duration(seconds: 3);
	String? _currentUploadSessionTrackId;
	String? _currentUserId;
	String? _currentUsername;

	List<UploadModel> get uploadedTracks {
		if (_selectedStatus == null) return _uploadedTracks;
		return _uploadedTracks
				.where((track) => track.status == _selectedStatus)
				.toList();
	}

	List<UploadModel> get allUploadedTracks => _uploadedTracks;

	bool get isLoading => _isLoading;
	bool get isUploading => _isUploading;
	String? get errorMessage => _errorMessage;
	String? get successMessage => _successMessage;
	String? get currentOperation => _currentOperation;
	UploadTrackStatus? get selectedStatus => _selectedStatus;
	String? get loadedArtistId => _loadedArtistId;
	bool get hasMoreArtistTracks => _hasMoreArtistTracks;
	int get lastLoadedArtistTracksPage => _lastLoadedArtistTracksPage;
	int get artistTracksTotal => _artistTracksTotal;
	String? get currentUserId => _currentUserId;
	String? get currentUsername => _currentUsername;

	List<UploadModel> publicArtistTracksForUser(String userId) {
		final normalizedUserId = userId.trim();
		if (normalizedUserId.isEmpty) return const <UploadModel>[];
		return List.unmodifiable(
			_publicArtistTracksByUserId[normalizedUserId] ?? const <UploadModel>[],
		);
	}

	bool publicArtistHasMoreForUser(String userId) {
		final normalizedUserId = userId.trim();
		if (normalizedUserId.isEmpty) return false;
		return _publicArtistHasMoreByUserId[normalizedUserId] ?? false;
	}

	int publicArtistLastPageForUser(String userId) {
		final normalizedUserId = userId.trim();
		if (normalizedUserId.isEmpty) return 1;
		return _publicArtistLastPageByUserId[normalizedUserId] ?? 1;
	}

	int publicArtistTotalForUser(String userId) {
		final normalizedUserId = userId.trim();
		if (normalizedUserId.isEmpty) return 0;
		return _publicArtistTotalByUserId[normalizedUserId] ?? 0;
	}

	bool isWaveformLoading(String trackId) =>
			_waveformRequestsInFlight.contains(trackId);

	String? waveformErrorForTrack(String trackId) =>
			_waveformErrorsByTrackId[trackId];

	UploadModel? get statusCardTrack {
		final sessionTrackId = _currentUploadSessionTrackId;
		if (sessionTrackId == null || sessionTrackId.trim().isEmpty) {
			return null;
		}

		for (final track in _uploadedTracks) {
			if (track.id == sessionTrackId) {
				return track;
			}
		}

		return null;
	}

	void updateCurrentUser({String? userId, String? username}) {
		final normalizedUserId = userId?.trim();
		final normalizedUsername = username?.trim();

		final nextUserId = (normalizedUserId == null || normalizedUserId.isEmpty)
				? null
				: normalizedUserId;
		final nextUsername =
				(normalizedUsername == null || normalizedUsername.isEmpty)
						? null
						: normalizedUsername;

		if (_currentUserId == nextUserId && _currentUsername == nextUsername) {
			return;
		}

		_currentUserId = nextUserId;
		_currentUsername = nextUsername;
	}

	bool isTrackOwnedByCurrentUser(UploadModel track) {
		final currentUserId = _currentUserId?.trim() ?? '';
		if (currentUserId.isEmpty) return false;

		final ownerToken = track.artistName.trim();
		if (ownerToken.isEmpty) return false;

		return ownerToken == currentUserId;
	}

	void _resetTransientMessages() {
		_errorMessage = null;
		_successMessage = null;
	}

	void setStatusFilter(UploadTrackStatus? status) {
		_selectedStatus = status;
		notifyListeners();
	}

	void clearError() {
		_errorMessage = null;
		notifyListeners();
	}

	void clearSuccessMessage() {
		_successMessage = null;
		notifyListeners();
	}

	void clearTransientMessages() {
		if (_errorMessage == null && _successMessage == null) return;
		_resetTransientMessages();
		notifyListeners();
	}

	void resetCurrentUploadSessionState({bool notify = true}) {
		final sessionTrackId = _currentUploadSessionTrackId;
		if (sessionTrackId != null && sessionTrackId.trim().isNotEmpty) {
			_stopTrackStatusPolling(sessionTrackId);
		}

		_isUploading = false;
		_currentOperation = null;
		_currentUploadSessionTrackId = null;
		_resetTransientMessages();

		_statusPollRequestsInFlight.clear();
		_waveformRequestsInFlight.clear();
		_waveformErrorsByTrackId.clear();

		if (notify) {
			notifyListeners();
		}
	}

	Future<void> loadCurrentArtistTracks({
		String? currentArtistId,
		int page = 1,
		int limit = 20,
		bool replace = true,
	}) async {
		final resolvedArtistId = (currentArtistId ?? '').trim().isNotEmpty
				? currentArtistId!.trim()
				: (_currentUserId?.trim() ?? '');

		if (resolvedArtistId.isEmpty) {
			_errorMessage =
					'You must be logged in to load your uploaded tracks.';
			notifyListeners();
			return;
		}

		await loadArtistTracks(
			artistId: resolvedArtistId,
			page: page,
			limit: limit,
			replace: replace,
		);
	}


	Future<void> loadArtistTracks({
		required String artistId,
		int page = 1,
		int limit = 20,
		bool replace = true,
	}) async {
		final normalizedArtistId = artistId.trim();
		if (normalizedArtistId.isEmpty) {
			_errorMessage = 'Artist id is required to load uploaded tracks.';
			notifyListeners();
			return;
		}

		_isLoading = true;
		_resetTransientMessages();
		_currentOperation = 'loadArtistTracks';
		notifyListeners();

		try {
			final pageResult = await _uploadService.getArtistTracks(
				artistId: normalizedArtistId,
				page: page,
				limit: limit,
			);

			final isCurrentUserArtist =
					normalizedArtistId == (_currentUserId?.trim() ?? '');

			if (isCurrentUserArtist) {
				_loadedArtistId = normalizedArtistId;
				_lastLoadedArtistTracksPage = pageResult.page;
				_artistTracksTotal = pageResult.total;
				_hasMoreArtistTracks = pageResult.hasMore;

				if (replace || page <= 1) {
					final remoteTracks = pageResult.tracks;
					final remoteIds = remoteTracks
							.map((track) => track.id)
							.where((id) => id.trim().isNotEmpty)
							.toSet();

					final localInFlightTracks = _uploadedTracks.where((track) {
						if (remoteIds.contains(track.id)) return false;
						return track.status == UploadTrackStatus.processing ||
									track.status == UploadTrackStatus.draft;
					}).toList();

					_uploadedTracks = [
						...remoteTracks,
						...localInFlightTracks,
					];
				} else {
					final existingById = {for (final track in _uploadedTracks) track.id: track};
					for (final track in pageResult.tracks) {
						existingById[track.id] = track;
					}
					_uploadedTracks = existingById.values.toList();
				}
			} else {
				_loadedArtistId = normalizedArtistId;
				_lastLoadedArtistTracksPage = pageResult.page;
				_artistTracksTotal = pageResult.total;
				_hasMoreArtistTracks = pageResult.hasMore;

				_publicArtistLastPageByUserId[normalizedArtistId] = pageResult.page;
				_publicArtistTotalByUserId[normalizedArtistId] = pageResult.total;
				_publicArtistHasMoreByUserId[normalizedArtistId] = pageResult.hasMore;

				final existingPublicTracks =
						_publicArtistTracksByUserId[normalizedArtistId] ?? const <UploadModel>[];

				if (replace || page <= 1) {
					_publicArtistTracksByUserId[normalizedArtistId] = pageResult.tracks;
				} else {
					final existingById = {
						for (final track in existingPublicTracks) track.id: track,
					};
					for (final track in pageResult.tracks) {
						existingById[track.id] = track;
					}
					_publicArtistTracksByUserId[normalizedArtistId] = existingById.values.toList();
				}
			}
		} catch (error) {
			_errorMessage = error.toString();
		} finally {
			_isLoading = false;
			_currentOperation = null;
			notifyListeners();
		}
	}

	Future<void> loadNextArtistTracks({
		required String artistId,
		int limit = 20,
	}) async {
		final normalizedArtistId = artistId.trim();
		if (normalizedArtistId.isEmpty) return;
		if (_isLoading) return;

		final isCurrentUserArtist =
				normalizedArtistId == (_currentUserId?.trim() ?? '');

		if (isCurrentUserArtist) {
			if (!_hasMoreArtistTracks) return;
			await loadArtistTracks(
				artistId: normalizedArtistId,
				page: _lastLoadedArtistTracksPage + 1,
				limit: limit,
				replace: false,
			);
			return;
		}

		final hasMore = _publicArtistHasMoreByUserId[normalizedArtistId] ?? false;
		if (!hasMore) return;

		final lastPage = _publicArtistLastPageByUserId[normalizedArtistId] ?? 1;
		await loadArtistTracks(
			artistId: normalizedArtistId,
			page: lastPage + 1,
			limit: limit,
			replace: false,
		);
	}

	Future<UploadModel?> uploadTrack(UploadModel track) async {
		if (_isUploading) return null;

		_isUploading = true;
		_resetTransientMessages();
		_currentOperation = 'uploadTrack';
		notifyListeners();

		try {
			final currentUserId = _currentUserId?.trim() ?? '';
			if (currentUserId.isEmpty) {
				throw const ApiException('You must be logged in to upload a track.');
			}

			final created = await _uploadService.createTrack(track);
			final previousSessionTrackId = _currentUploadSessionTrackId;
			if (previousSessionTrackId != null &&
						previousSessionTrackId != created.id) {
				_stopTrackStatusPolling(previousSessionTrackId);
			}
			_currentUploadSessionTrackId = created.id;
			_uploadedTracks = [
				created,
				..._uploadedTracks.where((existing) => existing.id != created.id),
			];
			_startTrackStatusPolling(created.id);
			_successMessage = 'Track uploaded successfully.';
			return created;
		} catch (error) {
			_errorMessage = error.toString();
			_successMessage = null;
			return null;
		} finally {
			_isUploading = false;
			_currentOperation = null;
			notifyListeners();
		}
	}

	Future<UploadModel?> updateTrack(UploadModel updatedTrack) async {
		_isLoading = true;
		_resetTransientMessages();
		_currentOperation = 'updateTrack';
		notifyListeners();

		try {
			// Metadata-only update. Artwork updates are handled by updateTrackArtwork.
			final saved = await _uploadService.updateTrackMetadata(
				trackId: updatedTrack.id,
				title: updatedTrack.title,
				genre: updatedTrack.genre,
				description: updatedTrack.description,
				tags: updatedTrack.tags,
				privacy: updatedTrack.privacy,
			);

			if (saved == null) return null;

			_uploadedTracks = _uploadedTracks
					.map(
						(track) =>
								(track.id == saved.id || track.id == updatedTrack.id)
									? saved
									: track,
					)
					.toList();
			_successMessage = 'Track changes saved.';
			return saved;
		} catch (error) {
			_errorMessage = error.toString();
			return null;
		} finally {
			_isLoading = false;
			_currentOperation = null;
			notifyListeners();
		}
	}

	Future<UploadModel?> updateTrackArtwork({
		required String trackId,
		required String artworkPathOrUrl,
	}) async {
		_isLoading = true;
		_resetTransientMessages();
		_currentOperation = 'updateTrackArtwork';
		notifyListeners();

		try {
			final saved = await _uploadService.updateTrackArtwork(
				trackId: trackId,
				artworkPathOrUrl: artworkPathOrUrl,
			);

			if (saved == null) return null;

			_uploadedTracks = _uploadedTracks
					.map(
						(track) =>
								(track.id == saved.id || track.id == trackId)
									? saved
									: track,
					)
					.toList();
			_successMessage = 'Artwork updated successfully.';
			return saved;
		} catch (error) {
			_errorMessage = error.toString();
			return null;
		} finally {
			_isLoading = false;
			_currentOperation = null;
			notifyListeners();
		}
	}

	Future<bool> deleteTrackById(String trackId) async {
		final existingTrack = getTrackById(trackId);
		_isLoading = true;
		_resetTransientMessages();
		_currentOperation = 'deleteTrackById';
		notifyListeners();

		try {
			_stopTrackStatusPolling(trackId);
			final deleted = await _uploadService.deleteTrack(trackId);
			if (deleted) {
				if (_currentUploadSessionTrackId == trackId) {
					_currentUploadSessionTrackId = null;
				}
				_uploadedTracks =
						_uploadedTracks.where((track) => track.id != trackId).toList();
				_successMessage = 'Track deleted successfully.';
			}
			return deleted;
		} catch (error) {
			_errorMessage = error.toString();
			if (existingTrack != null &&
						existingTrack.status == UploadTrackStatus.processing) {
				_startTrackStatusPolling(trackId);
			}
			return false;
		} finally {
			_isLoading = false;
			_currentOperation = null;
			notifyListeners();
		}
	}

	UploadModel? getTrackById(String trackId) {
		// Fast local lookup from provider source-of-truth state.
		try {
			return _uploadedTracks.firstWhere((track) => track.id == trackId);
		} catch (_) {
			return null;
		}
	}

	Future<UploadModel?> refreshTrackById(String trackId) async {
		if (trackId.trim().isEmpty) {
			_errorMessage = 'Track id is required.';
			notifyListeners();
			return null;
		}

		_isLoading = true;
		_currentOperation = 'refreshTrackById';
		_errorMessage = null;
		notifyListeners();

		try {
			final remoteTrack = await _uploadService.getTrackById(trackId);
			if (remoteTrack == null) return null;

			var replaced = false;
			_uploadedTracks = _uploadedTracks.map((track) {
				if (track.id == trackId || track.id == remoteTrack.id) {
					replaced = true;
					return remoteTrack;
				}
				return track;
			}).toList();

			if (!replaced) {
				_uploadedTracks = [remoteTrack, ..._uploadedTracks];
			}

			return remoteTrack;
		} catch (error) {
			_errorMessage = error.toString();
			return null;
		} finally {
			_isLoading = false;
			_currentOperation = null;
			notifyListeners();
		}
	}

	Future<List<double>?> fetchWaveformForTrack(
		String trackId, {
		bool forceRefresh = false,
	}) async {
		if (trackId.trim().isEmpty) return null;
		if (_waveformRequestsInFlight.contains(trackId)) return null;

		final existingTrack = getTrackById(trackId);
		if (!forceRefresh && existingTrack?.waveformPeaks?.isNotEmpty == true) {
			return existingTrack!.waveformPeaks;
		}

		_waveformRequestsInFlight.add(trackId);
		_waveformErrorsByTrackId.remove(trackId);
		notifyListeners();

		try {
			final peaks = await _uploadService.getWaveform(trackId);

			_uploadedTracks = _uploadedTracks
					.map(
						(track) => track.id == trackId
								? track.copyWith(
										waveformPeaks: peaks,
										waveformSamples: peaks.length,
								)
								: track,
					)
					.toList();

			return peaks;
		} catch (error) {
			_waveformErrorsByTrackId[trackId] = error.toString();
			return null;
		} finally {
			_waveformRequestsInFlight.remove(trackId);
			notifyListeners();
		}
	}

	void _startTrackStatusPolling(String trackId) {
		if (_statusPollTimersByTrackId.containsKey(trackId)) return;

		final existingTrack = getTrackById(trackId);
		if (existingTrack == null) return;
		if (existingTrack.status == UploadTrackStatus.finished ||
				existingTrack.status == UploadTrackStatus.failed) {
			return;
		}

		_pollTrackStatus(trackId);
		_statusPollTimersByTrackId[trackId] = Timer.periodic(
			_statusPollInterval,
			(_) => _pollTrackStatus(trackId),
		);
	}

	void _stopTrackStatusPolling(String trackId) {
		_statusPollTimersByTrackId.remove(trackId)?.cancel();
		_statusPollRequestsInFlight.remove(trackId);
	}

	Future<void> _pollTrackStatus(String trackId) async {
		if (_statusPollRequestsInFlight.contains(trackId)) return;
		_statusPollRequestsInFlight.add(trackId);

		try {
			final statusResult = await _uploadService.getTrackStatus(trackId);

			final updatedTracks = _uploadedTracks
					.map(
						(track) => track.id == trackId
								? track.copyWith(
										status: statusResult.status,
										progressPercent: statusResult.progressPercent,
										processingErrorMessage: statusResult.errorMessage,
								)
								: track,
					)
					.toList();

			_uploadedTracks = updatedTracks;

			if (statusResult.status == UploadTrackStatus.failed &&
						statusResult.errorMessage != null &&
						statusResult.errorMessage!.trim().isNotEmpty) {
				_errorMessage = statusResult.errorMessage;
			}

			if (statusResult.status == UploadTrackStatus.finished ||
						statusResult.status == UploadTrackStatus.failed) {
				_stopTrackStatusPolling(trackId);
			}
			notifyListeners();
		} catch (error) {
			_errorMessage = error.toString();
			_stopTrackStatusPolling(trackId);
			notifyListeners();
		} finally {
			_statusPollRequestsInFlight.remove(trackId);
		}
	}

	@override
	void dispose() {
		for (final timer in _statusPollTimersByTrackId.values) {
			timer.cancel();
		}
		_statusPollTimersByTrackId.clear();
		_statusPollRequestsInFlight.clear();
		_waveformRequestsInFlight.clear();
		_waveformErrorsByTrackId.clear();
		super.dispose();
	}
}
