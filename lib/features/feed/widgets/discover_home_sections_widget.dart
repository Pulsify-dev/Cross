import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/feed_provider.dart';
import 'discover_section_widget.dart';

class DiscoverHomeSectionsWidget extends StatelessWidget {
  const DiscoverHomeSectionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedProvider>(
      builder: (context, provider, child) {
        if (provider.isDiscoverHomeLoading && provider.discoverHomeSections.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.discoverHomeSections.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: provider.discoverHomeSections.map((section) {
            // We skip 'trending' since it's already rendered via TrendingTrackWidget
            // with its own custom genre filters
            if (section.id == 'trending') {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: DiscoverSectionWidget(section: section),
            );
          }).toList(),
        );
      },
    );
  }
}
