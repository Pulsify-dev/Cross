import 'package:flutter/material.dart';
//import '../../../core/theme/app_colors.dart';
import '../widgets/artwork_picker_card.dart';
import '../widgets/delete_track_confirm_dialog.dart';
import '../widgets/privacy_selector.dart';
import '../widgets/track_form_section_label.dart';
import '../widgets/track_primary_button.dart';
import '../widgets/track_text_field.dart';
import 'package:cross/features/upload/services/mock_uploaded_track.dart';
import 'package:cross/features/upload/services/mock_uploaded_tracks_store.dart';

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

  String _privacy = 'Public';

  MockUploadedTrack? get _track =>
    MockUploadedTracksStore.getById(widget.trackId);

  @override
  void initState() {
  super.initState();

  final track = _track;
  _titleController = TextEditingController(text: track?.title ?? '');
  _genreController = TextEditingController(text: track?.genre ?? '');
  _descriptionController =
    TextEditingController(text: track?.description ?? '');
  _tagsController = TextEditingController(text: track?.tags ?? '');
  _privacy = track?.privacy ?? 'Public';
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
    final track = _track;
    if (track == null) return;

    MockUploadedTracksStore.updateTrack(
      track.copyWith(
        title: _titleController.text.trim().isEmpty
            ? track.title
            : _titleController.text.trim(),
        genre: _genreController.text.trim().isEmpty
            ? track.genre
            : _genreController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: _tagsController.text.trim(),
        privacy: _privacy,
        status: 'Finished',
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Track changes saved')),
    );
    Navigator.pop(context);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const DeleteTrackConfirmDialog(),
    );

    if (confirmed == true && mounted) {
      MockUploadedTracksStore.removeTrack(widget.trackId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Track deleted')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_track == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Track')),
        body: const Center(child: Text('Track not found')),
      );
    }

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
                title: 'Update Artwork',
                onPick: () {},
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
            text: 'Save Changes',
            icon: Icons.save_outlined,
            onPressed: _saveChanges,
          ),
        ),
      ),
    );
  }
}