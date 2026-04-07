import 'package:flutter/foundation.dart';
import 'dart:async';
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
	String? _loadedArtistId;
	int _lastLoadedArtistTracksPage = 1;
	bool _hasMoreArtistTracks = false;
	final Duration _statusPollInterval = const Duration(seconds: 3);
	String? _currentUploadSessionTrackId;

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

	Future<void> loadCurrentArtistTracks({
		String? currentArtistId,
		int page = 1,
		int limit = 20,
		bool replace = true,
	}) async {
		final resolvedArtistId = (currentArtistId ?? '').trim();
		if (resolvedArtistId.isEmpty) {
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
		if (artistId.trim().isEmpty) {
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
				artistId: artistId,
				page: page,
				limit: limit,
			);

			_loadedArtistId = artistId;
			_lastLoadedArtistTracksPage = pageResult.page;
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
		} catch (error) {
			_errorMessage = error.toString();
		} finally {
			_isLoading = false;
			_currentOperation = null;
			notifyListeners();
		}
	}

	Future<UploadModel?> uploadTrack(UploadModel track) async {
		if (_isUploading) return null;

		_isUploading = true;
		_resetTransientMessages();
		_currentOperation = 'uploadTrack';
		notifyListeners();

		try {
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
