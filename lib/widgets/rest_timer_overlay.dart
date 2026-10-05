import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Floating, non-blocking Rest Timer for active gym lifters.
///
/// Features:
/// - Clean countdown HUD in Cyber Volt Lime.
/// - Controls: +30s, -15s, Skip Rest.
/// - Minimizable to a floating pill so lifters aren't blocked from scrolling.
/// - Heavy haptic vibration & sound chime at 0s.
class RestTimerOverlay extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback onFinished;
  final VoidCallback onCancel;

  const RestTimerOverlay({
    super.key,
    required this.initialSeconds,
    required this.onFinished,
    required this.onCancel,
  });

  @override
  State<RestTimerOverlay> createState() => _RestTimerOverlayState();
}

class _RestTimerOverlayState extends State<RestTimerOverlay> {
  late int _remaining;
  late int _total;
  Timer? _timer;
  bool _isMinimized = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.initialSeconds > 0 ? widget.initialSeconds : 90;
    _total = _remaining;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining > 1) {
        setState(() {
          _remaining--;
        });
      } else {
        _timer?.cancel();
        _onTimerComplete();
      }
    });
  }

  void _onTimerComplete() {
    // Vibration cues
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 300), () {
      HapticFeedback.vibrate();
    });
    // System audio click/chime
    SystemSound.play(SystemSoundType.click);

    widget.onFinished();
  }

  void _addSeconds(int secs) {
    setState(() {
      _remaining = (_remaining + secs).clamp(5, 600);
      if (_remaining > _total) _total = _remaining;
    });
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _total > 0 ? (_remaining / _total).clamp(0.0, 1.0) : 0.0;

    if (_isMinimized) {
      return Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24, right: 16),
          child: GestureDetector(
            onTap: () => setState(() => _isMinimized = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF14171F),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFB4F000), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, color: Color(0xFFB4F000), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(_remaining),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.open_in_full, color: Colors.white54, size: 14),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF14171F),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFB4F000).withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row with Minimize and Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.fitness_center, color: Color(0xFFB4F000), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'REST TIMER',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_fullscreen, color: Colors.white54, size: 16),
                      tooltip: 'Minimize',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _isMinimized = true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                      tooltip: 'Cancel Timer',
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onCancel,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Time Display & Circular Ring
            Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB4F000)),
                      ),
                      Text(
                        '${_remaining}s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTime(_remaining),
                        style: const TextStyle(
                          color: Color(0xFFB4F000),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Text(
                        'Catch your breath & prepare for next set',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quick Control Pills
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => _addSeconds(-15),
                    child: const Text('-15s', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => _addSeconds(30),
                    child: const Text('+30s', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB4F000),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () {
                      _timer?.cancel();
                      widget.onFinished();
                    },
                    child: const Text(
                      'SKIP REST ⚡',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
