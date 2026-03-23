import 'package:flutter/material.dart';
import 'package:unifye/features/swipe/models/swipe_candidate.dart';

class SwipeUserCard extends StatelessWidget {
  const SwipeUserCard({
    super.key,
    required this.candidate,
  });

  final SwipeCandidate candidate;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildProfilePhoto(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${candidate.gender} - DOB: ${candidate.dateOfBirth}',
                ),
                if (candidate.interests.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: candidate.interests
                        .map((interest) => Chip(label: Text(interest)))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhoto() {
    final imageUrl = candidate.imageUrl?.trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPhotoFallback();
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return const Center(
          child: CircularProgressIndicator(),
        );
      },
      errorBuilder: (_, __, ___) => _buildPhotoFallback(),
    );
  }

  Widget _buildPhotoFallback() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(
        Icons.person,
        size: 72,
        color: Colors.grey,
      ),
    );
  }
}
