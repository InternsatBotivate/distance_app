import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vendor_distance_app/models/vendor.dart';

class VendorBottomSheet extends StatelessWidget {
  const VendorBottomSheet({
    super.key,
    required this.vendor,
    required this.userMarker,
  });

  final Vendor vendor;
  final LatLng userMarker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top:Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(vendor.name, 
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 8),
          Text(vendor.address.isEmpty ? 'No addreess provided': vendor.address,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
          const Divider(height: 32),
          Row(
            children: [
              _InfoChip(icon: Icons.route_outlined, label: vendor.distance ?? 'Calculating...'),
              const SizedBox(width: 12),
              _InfoChip(icon: Icons.timer_outlined, label: vendor.duration ?? 'Calculating...'),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () async {
              final url = Uri.parse('https://www.google.com/maps/dir/?api=1&origin=${userMarker.latitude},${userMarker.longitude}&destination=${vendor.latitude},${vendor.longitude}&travelmode=driving');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                // handle error
              }
            },
            icon: const Icon(Icons.directions_car),
            label: const Text('Navigate with Google Maps'),
          )
        ],
      )
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;  


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withAlpha(128),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.secondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            )
          )
        ],
      ),
    );
  }
}