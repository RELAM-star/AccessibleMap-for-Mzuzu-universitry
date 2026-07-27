// lib/widgets/voice_assistant_widget.dart
// Drop this widget into any screen for voice control

import 'package:flutter/material.dart';
import '../services/voice_assistant_service.dart';

class VoiceAssistantWidget extends StatefulWidget {
  final VoiceAssistantService assistant;
  final VoidCallback? onOpenMap;
  final VoidCallback? onOpenToilets;
  final VoidCallback? onOpenReport;

  const VoiceAssistantWidget({
    super.key,
    required this.assistant,
    this.onOpenMap,
    this.onOpenToilets,
    this.onOpenReport,
  });

  @override
  State<VoiceAssistantWidget> createState() => _VoiceAssistantWidgetState();
}

class _VoiceAssistantWidgetState extends State<VoiceAssistantWidget>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  String _lastWords = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.25).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    widget.assistant.onListeningChanged = (listening) {
      if (mounted) setState(() => _isListening = listening);
    };

    widget.assistant.onCommand = _handleCommand;
  }

  void _handleCommand(String words) async {
    if (mounted) setState(() => _lastWords = words);

    // ── Navigate commands ──
    if (_contains(words, ['open map', 'campus map', 'show map', 'go to map', 'navigate', 'buildings'])) {
      await widget.assistant.speak('Opening campus map.');
      await Future.delayed(const Duration(milliseconds: 800));
      widget.onOpenMap?.call();
      return;
    }

    if (_contains(words, ['toilet', 'toilets', 'bathroom', 'restroom', 'washroom', 'accessible toilet', 'where is the toilet'])) {
      await widget.assistant.speak('Opening accessible toilets. I will help you find the nearest one.');
      await Future.delayed(const Duration(milliseconds: 800));
      widget.onOpenToilets?.call();
      return;
    }

    // ── Info commands ──
    if (_contains(words, ['hello', 'hi', 'hey', 'good morning', 'good afternoon'])) {
      await widget.assistant.speak('Hello! I am AccessMap, your campus navigation assistant. I can help you find buildings, toilets, and navigate Mzuzu University. What do you need?');
      return;
    }

    if (_contains(words, ['help', 'what can you do', 'commands', 'options'])) {
      await widget.assistant.speak('I can help you with the following. Say: open map, to see the campus map. Say: find toilet, to find accessible toilets. Say: hello, to greet me. Say: stop, to stop me talking. How can I help you?');
      return;
    }

    if (_contains(words, ['stop', 'quiet', 'silence', 'shut up', 'be quiet'])) {
      await widget.assistant.stopSpeaking();
      return;
    }

    if (_contains(words, ['where am i', 'my location', 'current location'])) {
      await widget.assistant.speak('You are at Mzuzu University campus. Open the campus map for detailed navigation.');
      return;
    }

    if (_contains(words, ['library', 'where is the library'])) {
      await widget.assistant.speak('The Mzuni Main Library has a step-free entrance on the east side. Braille materials are available. Open the campus map to see its exact location.');
      return;
    }

    if (_contains(words, ['admin', 'administration', 'registry', 'office'])) {
      await widget.assistant.speak('The Main Administration Block has ramp access at the main entrance with wide corridors. Open the map to navigate there.');
      return;
    }

    if (_contains(words, ['health', 'clinic', 'sick', 'doctor', 'health centre'])) {
      await widget.assistant.speak('The University Health Centre is fully accessible and provides priority service for disabled students. Open the map for directions.');
      return;
    }

    if (_contains(words, ['bus', 'transport', 'minibus', 'how to get to town'])) {
      await widget.assistant.speak('The main campus bus stop has a covered waiting area with low-floor minibuses. Open the campus map to find the bus stop location.');
      return;
    }

    if (_contains(words, ['emergency', 'help me', 'i need help', 'accident', 'unsafe'])) {
      await widget.assistant.speak('I am opening the report screen so you can share the problem quickly. If this is an immediate danger, contact campus security or ask someone nearby for help right away.');
      await Future.delayed(const Duration(milliseconds: 800));
      widget.onOpenReport?.call();
      return;
    }

    // ── Default fallback ──
    await widget.assistant.speak('Sorry, I did not understand "$words". Try saying: open map, find toilet, or help, for a list of commands.');
  }

  bool _contains(String input, List<String> keywords) {
    return keywords.any((k) => input.contains(k));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Last heard text bubble
        if (_lastWords.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
            ),
            child: Text(
              '"$_lastWords"',
              style: const TextStyle(fontSize: 12, color: Color(0xFF1A3C38), fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),

        // Listening label
        if (_isListening)
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text('Listening...', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),

        // Big mic button
        GestureDetector(
          onTap: () {
            if (_isListening) {
              widget.assistant.stopListening();
            } else {
              widget.assistant.speak('I am listening. What do you need?').then((_) {
                Future.delayed(const Duration(milliseconds: 1200), () {
                  widget.assistant.startListening();
                });
              });
            }
          },
          child: _isListening
              ? ScaleTransition(
                  scale: _pulseAnim,
                  child: _micButton(true),
                )
              : _micButton(false),
        ),
      ],
    );
  }

  Widget _micButton(bool active) {
    return Container(
      width: 68, height: 68,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE74C3C) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (active ? const Color(0xFFE74C3C) : const Color(0xFF1A7A6E)).withOpacity(0.4),
            blurRadius: active ? 20 : 12,
            spreadRadius: active ? 4 : 0,
          ),
        ],
      ),
      child: Icon(
        active ? Icons.mic : Icons.mic_none,
        color: active ? Colors.white : const Color(0xFF1A7A6E),
        size: 32,
      ),
    );
  }
}