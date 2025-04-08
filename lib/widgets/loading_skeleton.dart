import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16.0),
            _buildSkeletonItem(),
            _buildSkeletonItem(),
            _buildSkeletonItem(),
            _buildSkeletonItem(),
            _buildSkeletonItem(),
            _buildSkeletonItem(),
            _buildSkeletonItem(),
            _buildSkeletonItem(),
            _buildSkeletonItem(),
            _buildSkeletonItem(),
            _buildSkeletonItem(),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 20,
            width: double.infinity,
            color: Colors.white,
          ),
          const SizedBox(height: 4),
          Container(
            height: 16,
            width: 150,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}