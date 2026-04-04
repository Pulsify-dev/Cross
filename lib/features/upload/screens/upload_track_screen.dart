import 'package:flutter/material.dart';
//import '../../../core/theme/app_colors.dart';
import '../widgets/audio_picker_card.dart';
import '../widgets/artwork_picker_card.dart';
import '../widgets/privacy_selector.dart';
import '../widgets/track_form_section_label.dart';
import '../widgets/track_primary_button.dart';
import '../widgets/track_processing_card.dart';
import '../widgets/track_tab_switcher.dart';
import '../widgets/track_text_field.dart';
import '../widgets/upload_track_confirm_dialog.dart';
import '../widgets/waveform_preview_card.dart';
import 'package:cross/features/upload/services/mock_uploaded_track.dart';
import 'package:cross/features/upload/services/mock_uploaded_tracks_store.dart';

class UploadTrackScreen extends StatefulWidget {
  const UploadTrackScreen({super.key});

  @override
  State<UploadTrackScreen> createState() => _UploadTrackScreenState();
}

class _UploadTrackScreenState extends State<UploadTrackScreen> {
  UploadTrackTab _selectedTab = UploadTrackTab.trackInfo;
  late final PageController _pageController;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _collaboratorsController =
      TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  String _privacy = 'Public';
  String? _selectedAudioFile;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  void _onTabSelected(UploadTrackTab tab) {
    if (_selectedTab == tab) return;

    final targetPage = tab == UploadTrackTab.trackInfo ? 0 : 1;
    _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );

    setState(() => _selectedTab = tab);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _collaboratorsController.dispose();
    _genreController.dispose();
    _descriptionController.dispose();
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
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _confirmUpload() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const UploadTrackConfirmDialog(),
    );

    if (confirmed != true || !mounted) return;

    final title = _titleController.text.trim().isEmpty
        ? 'Untitled Track'
        : _titleController.text.trim();
    final genre = _genreController.text.trim().isEmpty
        ? 'Unknown Genre'
        : _genreController.text.trim();

    final newTrack = MockUploadedTrack(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      genre: genre,
      description: _descriptionController.text.trim(),
      tags: _tagsController.text.trim(),
      privacy: _privacy,
      imageUrl: MockUploadedTracksStore.defaultArtworkUrl,
      plays: '0 plays',
      status: 'Processing',
    );

    MockUploadedTracksStore.addTrack(newTrack);

    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Track uploaded (mock)')),
    );
  }

  Widget _buildTrackInfoTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TrackProcessingCard(
          progress: 0.35,
          statusText: 'PREPARING TO PROCESS',
          percentageText: '35%',
        ),
        const SizedBox(height: 18),
        AudioPickerCard(
          fileName: _selectedAudioFile,
          onPick: () {
            setState(() {
              _selectedAudioFile = 'my_track_demo.wav';
            });
          },
        ),
        const SizedBox(height: 18),
        ArtworkPickerCard(
          title: 'Cover Art',
          onPick: () {},
        ),
        const SizedBox(height: 22),

        const TrackFormSectionLabel(text: 'Track Title'),
        TrackTextField(
          controller: _titleController,
          hintText: 'Enter track title',
        ),
        const SizedBox(height: 18),

        const TrackFormSectionLabel(text: 'Artist Name'),
        TrackTextField(
          controller: TextEditingController(text: 'Mohammad Emad'),
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
    );
  }

  Widget _buildAdvancedTab() {
    final dateText =
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TrackFormSectionLabel(text: 'Waveform'),
        const WaveformPreviewCard(),
        const SizedBox(height: 24),
        const TrackFormSectionLabel(text: 'Release Date'),
        TrackTextField(
          controller: TextEditingController(text: dateText),
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
                },
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    child: _buildTrackInfoTab(),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    child: _buildAdvancedTab(),
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
            text: 'Upload Track',
            icon: Icons.upload_outlined,
            onPressed: _confirmUpload,
          ),
        ),
      ),
    );
  }
}