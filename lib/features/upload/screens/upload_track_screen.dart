import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
//import '../../../core/theme/app_colors.dart';
import '../widgets/audio_picker_card.dart';
import '../widgets/artwork_picker_card.dart';
import '../widgets/track_form_section_label.dart';
import '../widgets/track_primary_button.dart';
import '../widgets/track_processing_card.dart';
import '../widgets/track_tab_switcher.dart';
import '../widgets/track_text_field.dart';
import '../widgets/upload_track_confirm_dialog.dart';
import '../widgets/waveform_preview_card.dart';
import 'package:cross/features/upload/models/upload_model.dart';
import 'package:cross/providers/auth_provider.dart';
import 'package:cross/providers/upload_provider.dart';

class UploadTrackScreen extends StatefulWidget {
  const UploadTrackScreen({super.key});

  @override
  State<UploadTrackScreen> createState() => _UploadTrackScreenState();
}

class _UploadTrackScreenState extends State<UploadTrackScreen> {
  UploadTrackTab _selectedTab = UploadTrackTab.trackInfo;
  bool _isConfirmDialogOpen = false;
  late final PageController _pageController;
  late final TextEditingController _artistNameController;
  late final TextEditingController _releaseDateController;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _collaboratorsController =
      TextEditingController();
  String? _selectedGenre;

  static const List<String> _genres = [
    'Electronic', 'Hip-Hop', 'Rock', 'Pop', 'Jazz', 'Classical', 'R&B',
    'Soul', 'Reggae', 'Country', 'Metal', 'Folk', 'Latin', 'Blues',
    'Ambient', 'Acoustic', 'Soundtrack', 'Spoken Word', 'K-Pop',
    'Afrobeats', 'House', 'Techno', 'Lo-Fi', 'Other',
  ];
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _lyricsController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  String? _selectedAudioFile;
  String? _selectedAudioPath;
  String? _selectedArtworkFile;
  String? _selectedArtworkPath;
  Uint8List? _selectedArtworkBytes;
  DateTime _selectedDate = DateTime.now();
  bool _audioSelectedInCurrentDraft = false;
  bool _uploadSucceededForCurrentDraft = false;
  String? _pendingWaveformTrackId;
  UploadProvider? _uploadProviderForLifecycle;

  void _syncReleaseDateText() {
    _releaseDateController.text =
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'flac', 'aac'],
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final selectedPath = file.path;

    setState(() {
      _selectedAudioFile = file.name;
      _selectedAudioPath = selectedPath;
      _audioSelectedInCurrentDraft = selectedPath != null && selectedPath.isNotEmpty;
    });

    _markDraftChanged();
  }

  Future<void> _pickArtworkFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    setState(() {
      _selectedArtworkFile = file.name;
      _selectedArtworkPath = file.path;
      _selectedArtworkBytes = file.bytes;
    });

    _markDraftChanged();
  }

  bool get _hasRequiredInputs {
    final hasAudio = _selectedAudioPath != null && _selectedAudioPath!.trim().isNotEmpty;
    final hasArtwork =
        (_selectedArtworkPath != null && _selectedArtworkPath!.trim().isNotEmpty) ||
        _selectedArtworkBytes != null;
    return hasAudio && hasArtwork;
  }

  void _markDraftChanged() {
    if (!_uploadSucceededForCurrentDraft) return;

    setState(() {
      _uploadSucceededForCurrentDraft = false;
      _pendingWaveformTrackId = null;
    });
  }

  void _attachDraftChangeListeners() {
    for (final controller in [
      _titleController,
      _collaboratorsController,
      _descriptionController,
      _lyricsController,
      _tagsController,
    ]) {
      controller.addListener(_markDraftChanged);
    }
  }

  void _detachDraftChangeListeners() {
    for (final controller in [
      _titleController,
      _collaboratorsController,
      _descriptionController,
      _lyricsController,
      _tagsController,
    ]) {
      controller.removeListener(_markDraftChanged);
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _artistNameController = TextEditingController();
    _releaseDateController = TextEditingController();
    _syncReleaseDateText();
    _attachDraftChangeListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final username = authProvider.currentUser?.username.trim() ?? '';
      if (username.isNotEmpty) {
        _artistNameController.text = username;
      }
    });
  }

  void _onTabSelected(UploadTrackTab tab) {
    if (_selectedTab == tab) return;

    final targetPage = tab == UploadTrackTab.trackInfo ? 0 : 1;
    _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );

    if (tab == UploadTrackTab.advanced) {
      _requestWaveformForCurrentTrack();
    }

    setState(() => _selectedTab = tab);
  }

  void _requestWaveformForCurrentTrack() {
    final provider = context.read<UploadProvider>();
    final track = provider.statusCardTrack;
    if (track == null) return;
    if (track.id.trim().isEmpty) return;
    unawaited(provider.fetchWaveformForTrack(track.id));
  }

  void _maybeFetchWaveformAfterUploadSuccess(UploadProvider provider) {
    final trackId = _pendingWaveformTrackId;
    if (trackId == null || trackId.trim().isEmpty) return;

    final track = provider.getTrackById(trackId);
    if (track == null) return;

    if (track.waveformPeaks?.isNotEmpty == true) {
      _pendingWaveformTrackId = null;
      return;
    }

    if (provider.isWaveformLoading(trackId)) return;

    if (track.status == UploadTrackStatus.finished) {
      _pendingWaveformTrackId = null;
      unawaited(provider.fetchWaveformForTrack(trackId, forceRefresh: true));
      return;
    }

    if (track.status == UploadTrackStatus.failed) {
      _pendingWaveformTrackId = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _uploadProviderForLifecycle ??= context.read<UploadProvider>();
  }

  @override
  void dispose() {
    _uploadProviderForLifecycle?.resetCurrentUploadSessionState(notify: false);

    _selectedAudioFile = null;
    _selectedAudioPath = null;
    _selectedArtworkFile = null;
    _selectedArtworkPath = null;
    _selectedArtworkBytes = null;
    _audioSelectedInCurrentDraft = false;
    _uploadSucceededForCurrentDraft = false;
    _pendingWaveformTrackId = null;

    _detachDraftChangeListeners();
    _pageController.dispose();
    _artistNameController.dispose();
    _releaseDateController.dispose();
    _titleController.dispose();
    _collaboratorsController.dispose();
    _descriptionController.dispose();
    _lyricsController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickReleaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _syncReleaseDateText();
      });

      _markDraftChanged();
    }
  }

  Future<void> _confirmUpload() async {
    final provider = context.read<UploadProvider>();
    if (provider.isUploading || _isConfirmDialogOpen) return;

    _isConfirmDialogOpen = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const UploadTrackConfirmDialog(),
    );
    _isConfirmDialogOpen = false;

    if (confirmed != true || !mounted) return;

    if (_selectedAudioPath == null || _selectedAudioPath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose an audio file first')),
      );
      return;
    }

    if ((_selectedArtworkPath == null || _selectedArtworkPath!.isEmpty) &&
        _selectedArtworkBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a cover image first')),
      );
      return;
    }

    final title = _titleController.text.trim().isEmpty
        ? 'Untitled Track'
        : _titleController.text.trim();
    final genre = _selectedGenre ?? 'Other';

    final tags = _tagsController.text
      .split(RegExp(r'[\s,]+'))
      .where((part) => part.trim().isNotEmpty)
      .map((part) => part.replaceFirst('#', '').trim())
      .where((part) => part.isNotEmpty)
      .toList();

    final newTrack = UploadModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      artistName: _artistNameController.text.trim(),
      collaborators: _collaboratorsController.text
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(),
      genre: genre,
      description: _descriptionController.text.trim(),
      lyrics: _lyricsController.text.trim().isEmpty ? null : _lyricsController.text.trim(),
      tags: tags,
      // Upload screen defaults to private; privacy can be changed in edit screen.
      privacy: UploadTrackPrivacy.private.name,
      artworkPathOrUrl: _selectedArtworkPath ?? '',
      audioPathOrFileName: _selectedAudioPath!,
      status: UploadTrackStatus.processing,
      releaseDate: _selectedDate,
      artworkBytes: _selectedArtworkBytes,
    );

    final uploadProvider = context.read<UploadProvider>();
    final created = await uploadProvider.uploadTrack(newTrack);
    if (!mounted) return;

    if (created == null) {
      final errorText = uploadProvider.errorMessage ?? 'Failed to upload track.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorText),
        ),
      );
      uploadProvider.clearError();
      return;
    }

    final successText = uploadProvider.successMessage ?? 'Track uploaded.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successText),
      ),
    );

    setState(() {
      _uploadSucceededForCurrentDraft = true;
      _pendingWaveformTrackId = created.id;
      _selectedTab = UploadTrackTab.advanced;
    });
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );

    uploadProvider.clearSuccessMessage();
  }

  String _statusLabelForCard(UploadProvider provider) {
    final statusTrack = provider.statusCardTrack;

    if (provider.isUploading) {
      return 'UPLOADING FILES';
    }

    if (statusTrack == null) {
      return 'READY TO UPLOAD';
    }

    switch (statusTrack.status) {
      case UploadTrackStatus.processing:
        return 'PROCESSING TRACK';
      case UploadTrackStatus.finished:
        return 'PROCESSING COMPLETE';
      case UploadTrackStatus.failed:
        return 'PROCESSING FAILED';
      case UploadTrackStatus.draft:
        return 'READY TO UPLOAD';
    }
  }

  double? _progressForCard(UploadProvider provider) {
    if (provider.isUploading) return null;

    final statusTrack = provider.statusCardTrack;
    if (statusTrack == null) return 0.0;

    final progressPercent = statusTrack.progressPercent;
    if (progressPercent != null) {
      return (progressPercent / 100).clamp(0.0, 1.0);
    }

    switch (statusTrack.status) {
      case UploadTrackStatus.finished:
        return 1.0;
      case UploadTrackStatus.failed:
        return 0.0;
      case UploadTrackStatus.processing:
        return null;
      case UploadTrackStatus.draft:
        return 0.0;
    }
  }

  Widget _buildTrackInfoTab(UploadProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TrackProcessingCard(
          progress: _progressForCard(provider),
          statusText: _statusLabelForCard(provider),
          percentageText: null,
        ),
        const SizedBox(height: 18),
        AudioPickerCard(
          key: const Key('upload_audio_picker'),
          fileName: _selectedAudioFile,
          onPick: _pickAudioFile,
        ),
        const SizedBox(height: 18),
        ArtworkPickerCard(
          key: const Key('upload_artwork_picker'),
          title: _selectedArtworkFile ?? 'Cover Art',
          imageBytes: _selectedArtworkBytes,
          onPick: _pickArtworkFile,
        ),
        const SizedBox(height: 22),

        const TrackFormSectionLabel(text: 'Track Title'),
        TrackTextField(
          key: const Key('upload_title_field'),
          controller: _titleController,
          hintText: 'Enter track title',
        ),
        const SizedBox(height: 18),

        const TrackFormSectionLabel(text: 'Artist Name'),
        TrackTextField(
          controller: _artistNameController,
          hintText: '',
          readOnly: true,
          suffixIcon: const Icon(Icons.lock_outline),
        ),
        const SizedBox(height: 18),

        const TrackFormSectionLabel(text: 'Collaborators'),
        TrackTextField(
          controller: _collaboratorsController,
          hintText: 'Add collaborators',
        ),
        const SizedBox(height: 18),

        const TrackFormSectionLabel(text: 'Genre'),
        DropdownButtonFormField<String>(
          key: const Key('upload_genre_dropdown'),
          initialValue: _selectedGenre,
          hint: const Text('Choose genre'),
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).inputDecorationTheme.fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.4),
            ),
          ),
          dropdownColor: Theme.of(context).colorScheme.surface,
          items: _genres.map((g) => DropdownMenuItem(
            key: Key('upload_genre_item_${g.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}'),
            value: g,
            child: Text(g),
          )).toList(),
          onChanged: (value) {
            setState(() => _selectedGenre = value);
            _markDraftChanged();
          },
        ),
        const SizedBox(height: 18),

        const TrackFormSectionLabel(text: 'Description'),
        TrackTextField(
          key: const Key('upload_description_field'),
          controller: _descriptionController,
          hintText: 'Describe your track',
          maxLines: 4,
        ),
        const SizedBox(height: 18),

        const TrackFormSectionLabel(text: 'Lyrics'),
        TrackTextField(
          controller: _lyricsController,
          hintText: 'Enter track lyrics...',
          maxLines: 8,
        ),
        const SizedBox(height: 18),

        const TrackFormSectionLabel(text: 'Tags'),
        TrackTextField(
          controller: _tagsController,
          hintText: '#track #music #demo',
        ),
      ],
    );
  }

  Widget _buildAdvancedTab(UploadProvider provider) {
    final statusTrack = provider.statusCardTrack;
    final trackId = statusTrack?.id ?? '';
    final currentTrack = trackId.isEmpty ? null : provider.getTrackById(trackId);
    final previewPeaks = currentTrack?.waveformPeaks;
    final isPreviewLoading = trackId.isNotEmpty
        ? provider.isWaveformLoading(trackId)
        : false;
    final previewError = trackId.isNotEmpty
        ? provider.waveformErrorForTrack(trackId)
        : null;
    final neutralText = _audioSelectedInCurrentDraft
        ? 'Waveform will appear after upload completes.'
        : 'Choose an audio file, then upload to generate waveform.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TrackFormSectionLabel(text: 'Waveform'),
        WaveformPreviewCard(
          peaks: previewPeaks,
          isLoading: isPreviewLoading,
          errorText: previewError,
          emptyText: neutralText,
          showErrorDetails: false,
        ),
        const SizedBox(height: 24),
        const TrackFormSectionLabel(text: 'Release Date'),
        TrackTextField(
          controller: _releaseDateController,
          hintText: '',
          readOnly: true,
          onTap: _pickReleaseDate,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final uploadProvider = context.watch<UploadProvider>();
    _maybeFetchWaveformAfterUploadSuccess(uploadProvider);
    final isButtonEnabled =
        _hasRequiredInputs &&
        !uploadProvider.isUploading &&
        !_uploadSucceededForCurrentDraft;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Track'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            TrackTabSwitcher(
              currentTab: _selectedTab,
              onTrackInfoTap: () {
                _onTabSelected(UploadTrackTab.trackInfo);
              },
              onAdvancedTap: () {
                _onTabSelected(UploadTrackTab.advanced);
              },
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _selectedTab =
                        index == 0 ? UploadTrackTab.trackInfo : UploadTrackTab.advanced;
                  });

                  if (index == 1) {
                    _requestWaveformForCurrentTrack();
                  }
                },
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    child: _buildTrackInfoTab(uploadProvider),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    child: _buildAdvancedTab(uploadProvider),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: TrackPrimaryButton(
            key: const Key('upload_submit_button'),
            text: uploadProvider.isUploading
                ? 'Uploading...'
                : (_uploadSucceededForCurrentDraft ? 'Uploaded' : 'Upload Track'),
            icon: Icons.upload_outlined,
            onPressed: isButtonEnabled ? _confirmUpload : null,
          ),
        ),
      ),
    );
  }
}