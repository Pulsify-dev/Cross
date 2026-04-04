import 'package:flutter/material.dart';
//import '../../../core/theme/app_colors.dart';
import '../widgets/artwork_picker_card.dart';
import '../widgets/delete_track_confirm_dialog.dart';
import '../widgets/privacy_selector.dart';
import '../widgets/track_form_section_label.dart';
import '../widgets/track_primary_button.dart';
import '../widgets/track_text_field.dart';

class EditUploadedTrackScreen extends StatefulWidget {
  const EditUploadedTrackScreen({super.key});

  @override
  State<EditUploadedTrackScreen> createState() => _EditUploadedTrackScreenState();
}

class _EditUploadedTrackScreenState extends State<EditUploadedTrackScreen> {
  final TextEditingController _titleController =
      TextEditingController(text: 'Midnight Monolith');
  final TextEditingController _genreController =
      TextEditingController(text: 'Electronic');
  final TextEditingController _descriptionController =
      TextEditingController(text: 'A moody late-night synth track.');
  final TextEditingController _tagsController =
      TextEditingController(text: '#night #electronic #synth');

  String _privacy = 'Public';

  @override
  void dispose() {
    _titleController.dispose();
    _genreController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Track changes saved')),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const DeleteTrackConfirmDialog(),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Track deleted')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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