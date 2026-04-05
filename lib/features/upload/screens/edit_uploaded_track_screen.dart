import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
//import '../../../core/theme/app_colors.dart';
import '../widgets/artwork_picker_card.dart';
import '../widgets/delete_track_confirm_dialog.dart';
import '../widgets/privacy_selector.dart';
import '../widgets/track_form_section_label.dart';
import '../widgets/track_primary_button.dart';
import '../widgets/track_text_field.dart';
import 'package:cross/features/upload/models/upload_model.dart';
import 'package:cross/providers/upload_provider.dart';

class EditUploadedTrackScreen extends StatefulWidget {
  const EditUploadedTrackScreen({
    super.key,
    required this.trackId,
  });

  final String trackId;

  @override
  State<EditUploadedTrackScreen> createState() => _EditUploadedTrackScreenState();
}

class _EditUploadedTrackScreenState extends State<EditUploadedTrackScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _genreController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagsController;
  bool _didInitForm = false;
  bool _isSaving = false;
  bool _isUpdatingArtwork = false;
  Uint8List? _selectedArtworkPreviewBytes;

  String _privacy = UploadTrackPrivacy.private.name;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController();
    _genreController = TextEditingController();
    _descriptionController = TextEditingController();
    _tagsController = TextEditingController();

		WidgetsBinding.instance.addPostFrameCallback((_) {
			if (!mounted) return;
			unawaited(context.read<UploadProvider>().refreshTrackById(widget.trackId));
		});
  }

  void _syncControllersFromTrack(UploadModel track) {
    if (_didInitForm) return;

    _titleController.text = track.title;
    _genreController.text = track.genre;
    _descriptionController.text = track.description;
    _tagsController.text = track.tags.map((tag) => '#$tag').join(' ');
    _privacy = track.privacy;
    _didInitForm = true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _genreController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;

    final provider = context.read<UploadProvider>();
    final track = provider.getTrackById(widget.trackId);
    if (track == null) return;

    setState(() => _isSaving = true);

    final parsedTags = _tagsController.text
        .split(RegExp(r'[\s,]+'))
        .where((part) => part.trim().isNotEmpty)
        .map((part) => part.replaceFirst('#', '').trim())
        .where((part) => part.isNotEmpty)
        .toList();

    final saved = await provider.updateTrack(
      track.copyWith(
        title: _titleController.text.trim().isEmpty
            ? track.title
            : _titleController.text.trim(),
        genre: _genreController.text.trim().isEmpty
            ? track.genre
            : _genreController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: parsedTags,
        privacy: _privacy,
        status: UploadTrackStatus.finished,
      ),
    );
    if (!mounted) return;

    setState(() => _isSaving = false);

    if (saved == null) {
      final errorText = provider.errorMessage ?? 'Failed to save track changes.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorText)),
      );
      provider.clearError();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.successMessage ?? 'Track changes saved')),
    );
    provider.clearSuccessMessage();
    Navigator.pop(context);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const DeleteTrackConfirmDialog(),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final provider = context.read<UploadProvider>();
    final deleted = await provider.deleteTrackById(widget.trackId);
    if (!mounted) return;

    if (!deleted) {
      final errorText = provider.errorMessage ?? 'Failed to delete track.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorText)),
      );
      provider.clearError();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.successMessage ?? 'Track deleted')),
    );
    provider.clearSuccessMessage();
    Navigator.pop(context);
  }

  Future<void> _pickAndUpdateArtwork(UploadModel track) async {
    if (_isUpdatingArtwork) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );

    if (!mounted) return;

    if (result == null || result.files.isEmpty) return;

    final selected = result.files.single;
    final selectedPath = selected.path;
    if (selectedPath == null || selectedPath.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a valid artwork file.')),
      );
      return;
    }

    setState(() {
      _isUpdatingArtwork = true;
      _selectedArtworkPreviewBytes = selected.bytes;
    });

    final provider = context.read<UploadProvider>();
    try {
      final updated = await provider.updateTrackArtwork(
        trackId: track.id,
        artworkPathOrUrl: selectedPath,
      );
      if (!mounted) return;

      if (updated == null) {
        final errorText = provider.errorMessage ?? 'Failed to update artwork.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorText)),
        );
        provider.clearError();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.successMessage ?? 'Artwork updated')),
      );
      provider.clearSuccessMessage();
    } finally {
      if (mounted) {
        setState(() => _isUpdatingArtwork = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = context.watch<UploadProvider>().getTrackById(widget.trackId);

    if (track == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Track')),
        body: const Center(child: Text('Track not found')),
      );
    }

    _syncControllersFromTrack(track);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Track'),
        actions: [
          IconButton(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Track',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ArtworkPickerCard(
                title: _isUpdatingArtwork ? 'Updating Artwork...' : 'Update Artwork',
                imageBytes: _selectedArtworkPreviewBytes ?? track.artworkBytes,
                imageUrl: (_selectedArtworkPreviewBytes == null &&
                        track.artworkBytes == null)
                    ? track.artworkPathOrUrl
                    : null,
                onPick: () => _pickAndUpdateArtwork(track),
              ),
              const SizedBox(height: 22),

              const TrackFormSectionLabel(text: 'Track Title'),
              TrackTextField(
                controller: _titleController,
                hintText: 'Enter track title',
              ),
              const SizedBox(height: 18),

              const TrackFormSectionLabel(text: 'Genre'),
              TrackTextField(
                controller: _genreController,
                hintText: 'Choose genre',
                suffixIcon: const Icon(Icons.keyboard_arrow_down),
              ),
              const SizedBox(height: 18),

              const TrackFormSectionLabel(text: 'Description'),
              TrackTextField(
                controller: _descriptionController,
                hintText: 'Describe your track',
                maxLines: 4,
              ),
              const SizedBox(height: 18),

              const TrackFormSectionLabel(text: 'Tags'),
              TrackTextField(
                controller: _tagsController,
                hintText: '#track #music #demo',
              ),
              const SizedBox(height: 18),

              const TrackFormSectionLabel(text: 'Visibility'),
              PrivacySelector(
                selectedValue: _privacy,
                onChanged: (value) {
                  setState(() => _privacy = value);
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: TrackPrimaryButton(
            text: _isSaving ? 'Saving...' : 'Save Changes',
            icon: Icons.save_outlined,
            onPressed: _isSaving ? () {} : _saveChanges,
          ),
        ),
      ),
    );
  }
}