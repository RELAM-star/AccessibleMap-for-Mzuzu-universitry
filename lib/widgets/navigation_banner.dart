import 'package:flutter/material.dart';

/// Live turn-by-turn instruction banner shown while a NavigationController
/// session is active. Shared across the map, toilets, and nearby-buildings
/// screens so guided walking looks and behaves the same everywhere.
class NavigationBanner extends StatelessWidget {
  final String destinationName;
  final String instruction;
  final double? distanceMeters;
  final VoidCallback onStop;

  const NavigationBanner({
    super.key,
    required this.destinationName,
    required this.instruction,
    required this.distanceMeters,
    required this.onStop,
  });

  String get _distanceText {
    final d = distanceMeters;
    if (d == null) return '';
    if (d < 15) return 'now';
    if (d < 1000) return 'in ${d.toStringAsFixed(0)} m';
    return 'in ${(d / 1000).toStringAsFixed(1)} km';
  }

  IconData get _icon {
    final i = instruction.toLowerCase();
    if (i.contains('arrived')) return Icons.flag;
    if (i.contains('left')) return Icons.turn_left;
    if (i.contains('right')) return Icons.turn_right;
    if (i.contains('roundabout') || i.contains('rotary')) return Icons.roundabout_left;
    if (i.contains('depart') || i.contains('head')) return Icons.play_arrow;
    return Icons.straight;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF135C52),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
          child: Icon(_icon, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Navigating to $destinationName',
                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(instruction,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            if (_distanceText.isNotEmpty)
              Text(_distanceText, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
          ]),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onStop,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: const Text('Stop', style: TextStyle(color: Color(0xFF135C52), fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ),
      ]),
    );
  }
}
