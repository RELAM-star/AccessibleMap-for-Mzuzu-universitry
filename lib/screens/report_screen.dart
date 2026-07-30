// lib/screens/report_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  final FirestoreService _firestore = FirestoreService();
  bool _sttAvailable = false;

  int _step = 0;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isSubmitting = false;
  String _listenedWords = '';

  String? _reportType;
  String? _location;
  String _crowdedSpot = '';

  final List<Map<String, dynamic>> _reportTypes = [
    {'type': 'Blocked Path',      'icon': Icons.block,              'color': const Color(0xFFE74C3C), 'keyword': ['blocked', 'block', 'path', 'route', 'closed']},
    {'type': 'Construction Area', 'icon': Icons.construction,       'color': const Color(0xFFF39C12), 'keyword': ['construction', 'building', 'works', 'digging']},
    {'type': 'Crowded Location',  'icon': Icons.people,             'color': const Color(0xFF7B8FF7), 'keyword': ['crowd', 'crowded', 'people', 'busy', 'full']},
    {'type': 'Broken Ramp',       'icon': Icons.accessible_forward, 'color': const Color(0xFFE67E22), 'keyword': ['ramp', 'broken', 'damaged', 'wheelchair', 'steps']},
    {'type': 'Poor Lighting',     'icon': Icons.lightbulb_outline,  'color': const Color(0xFF57CC99), 'keyword': ['dark', 'light', 'lighting', 'dim', 'night']},
    {'type': 'Other Hazard',      'icon': Icons.warning_amber,      'color': const Color(0xFFB57BEE), 'keyword': ['other', 'hazard', 'danger', 'problem', 'issue']},
  ];

  final Map<String, List<String>> _locationKeywords = {
    'Main Administration Block': ['admin', 'administration', 'registry', 'office'],
    'Mzuni Main Library':        ['library', 'lib', 'books'],
    'Faculty of Humanities':     ['humanities', 'arts', 'foh'],
    'Faculty of Science & Engineering': ['science', 'engineering', 'fose', 'lab'],
    'Faculty of Business':       ['business', 'fob', 'commerce'],
    'Faculty of Education':      ['education', 'foe', 'teaching'],
    'Student Centre':            ['student centre', 'student center', 'centre', 'center'],
    'University Chapel':         ['chapel', 'church', 'worship'],
    'Sports Complex':            ['sports', 'field', 'gym', 'complex', 'pitch'],
    "Chancellor's Hostel":       ['chancellor', 'male hostel', 'boys'],
    'Female Hostel':             ['female', 'girls', 'ladies', 'women'],
    'University Health Centre':  ['health', 'clinic', 'hospital', 'nurse'],
    'Main Campus Bus Stop':      ['bus', 'bus stop', 'transport', 'stage'],
    'Main Cafeteria':            ['cafeteria', 'canteen', 'food', 'dining', 'eat'],
    'ICT Centre':                ['ict', 'computer', 'computers', 'it centre'],
  };

  @override
  void initState() {
    super.initState();
    _setupTts();
    _setupStt();
  }

  Future<void> _setupTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.42);
    await _tts.setVolume(1.0);
    _tts.setErrorHandler((error) {});
    _tts.setStartHandler(() => setState(() => _isSpeaking = true));
    _tts.setCompletionHandler(() => setState(() => _isSpeaking = false));
  }

  Future<void> _setupStt() async {
    _sttAvailable = await _stt.initialize();
    if (mounted) _startWizard();
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    setState(() => _isSpeaking = true);
    await _tts.speak(text);
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 200));
      return _isSpeaking;
    });
  }

  Future<void> _listen({
    required int seconds,
    required void Function(String) onResult,
  }) async {
    if (!_sttAvailable) {
      await _speak('Speech not available. Please tap the option on screen.');
      return;
    }
    setState(() {
      _isListening = true;
      _listenedWords = '';
    });
    await _stt.listen(
      onResult: (result) {
        setState(() => _listenedWords = result.recognizedWords);
        if (result.finalResult) {
          setState(() => _isListening = false);
          onResult(result.recognizedWords.toLowerCase());
        }
      },
      listenFor: Duration(seconds: seconds),
      pauseFor: const Duration(seconds: 2),
    );
  }

  Future<void> _startWizard() async {
    setState(() => _step = 0);
    await _speak('Welcome to the report screen. Tap the big microphone button to begin.');
  }

  Future<void> _askProblemType() async {
    setState(() => _step = 1);
    await _speak('Step one. What type of problem are you reporting? Say: Blocked Path, Construction Area, Crowded Location, Broken Ramp, Poor Lighting, or Other Hazard.');
    await _listen(seconds: 10, onResult: (words) async {
      String? matched = _matchType(words);
      if (matched != null) {
        setState(() => _reportType = matched);
        await _speak('Got it. You said $matched.');
        await _askLocation();
      } else {
        await _speak('I did not catch that. Please try again.');
        await _askProblemType();
      }
    });
  }

  Future<void> _askLocation() async {
    setState(() => _step = 2);
    await _speak('Step two. Where is the problem? Say the building name. For example: Library, Admin Block, Student Centre, or Cafeteria.');
    await _listen(seconds: 10, onResult: (words) async {
      String? matched = _matchLocation(words);
      if (matched != null) {
        setState(() => _location = matched);
        await _speak('Location set to $matched.');
        if (_reportType == 'Crowded Location') {
          await _askCrowdedSpot();
        } else {
          await _askConfirm();
        }
      } else {
        await _speak('I could not match that location. Please try again.');
        await _askLocation();
      }
    });
  }

  Future<void> _askCrowdedSpot() async {
    setState(() => _step = 3);
    await _speak('Step three. Where exactly is it crowded? For example: near the entrance, in the corridor, or at the stairs.');
    await _listen(seconds: 10, onResult: (words) async {
      if (words.length > 2) {
        setState(() => _crowdedSpot = words);
        await _speak('You said: $words.');
        await _askConfirm();
      } else {
        await _speak('Please describe the crowded spot again.');
        await _askCrowdedSpot();
      }
    });
  }

  Future<void> _askConfirm() async {
    setState(() => _step = 4);
    String summary = 'Problem: $_reportType. Location: $_location.';
    if (_crowdedSpot.isNotEmpty) summary += ' Crowded spot: $_crowdedSpot.';
    await _speak('Step four. Here is your report. $summary. Say YES to submit, or say REDO to start over.');
    await _listen(seconds: 8, onResult: (words) async {
      if (words.contains('yes') || words.contains('submit') || words.contains('confirm')) {
        await _doSubmit();
      } else if (words.contains('redo') || words.contains('no') || words.contains('again')) {
        setState(() {
          _reportType = null;
          _location = null;
          _crowdedSpot = '';
        });
        await _speak('Starting over.');
        await _askProblemType();
      } else {
        await _speak('Say YES to submit or REDO to start again.');
        await _askConfirm();
      }
    });
  }

  Future<void> _doSubmit() async {
    setState(() { _isSubmitting = true; _step = 5; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      await _firestore.submitReport({
        'type': _reportType,
        'location': _location,
        'crowdedSpot': _crowdedSpot,
        'userId': user?.uid ?? 'anonymous',
      });
    } catch (e) {
      await _speak('There was an error submitting your report. Please try again.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: $e'), backgroundColor: const Color(0xFFD35400)),
        );
      }
      setState(() { _isSubmitting = false; _step = 4; });
      return;
    }
    setState(() => _isSubmitting = false);
    await _speak('Your report has been submitted successfully. Thank you for helping other students stay safe on campus.');
  }

  String? _matchType(String spoken) {
    for (final r in _reportTypes) {
      for (final kw in r['keyword'] as List) {
        if (spoken.contains(kw)) return r['type'] as String;
      }
    }
    return null;
  }

  String? _matchLocation(String spoken) {
    for (final entry in _locationKeywords.entries) {
      for (final kw in entry.value) {
        if (spoken.contains(kw)) return entry.key;
      }
    }
    return null;
  }

  Color get _stepColor {
    if (_step == 1) return const Color(0xFFE74C3C);
    if (_step == 2) return const Color(0xFF135C52);
    if (_step == 3) return const Color(0xFF7B8FF7);
    if (_step == 4) return const Color(0xFFF39C12);
    return const Color(0xFF135C52);
  }

  String get _stepTitle {
    if (_step == 0) return 'Ready to Report?';
    if (_step == 1) return 'What is the problem?';
    if (_step == 2) return 'Where is it?';
    if (_step == 3) return 'Where exactly?';
    if (_step == 4) return 'Confirm your report';
    if (_step == 5) return _isSubmitting ? 'Submitting...' : 'Report Submitted!';
    return '';
  }

  String get _stepHint {
    if (_step == 0) return 'Tap the button below to start the voice wizard';
    if (_step == 1) return 'Say: Blocked Path, Construction, Crowded Location,\nBroken Ramp, Poor Lighting, or Other Hazard';
    if (_step == 2) return 'Say the building name:\nLibrary, Admin Block, Cafeteria...';
    if (_step == 3) return 'Describe where exactly:\nnear entrance, corridor, stairs...';
    if (_step == 4) return 'Say YES to submit\nor REDO to start over';
    if (_step == 5) return _isSubmitting ? 'Please wait...' : 'Thank you for keeping campus safe!';
    return '';
  }

  IconData get _stepIcon {
    if (_step == 0) return Icons.campaign;
    if (_step == 1) return Icons.report_problem;
    if (_step == 2) return Icons.location_on;
    if (_step == 3) return Icons.people;
    if (_step == 4) return Icons.check_circle_outline;
    if (_step == 5) return _isSubmitting ? Icons.hourglass_top : Icons.check_circle;
    return Icons.mic;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF135C52),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Report a Problem',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Restart',
              onPressed: _startWizard),
        ],
      ),
      body: Column(
        children: [
          if (_step > 0 && _step < 5)
            LinearProgressIndicator(
              value: _step / 4,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(_stepColor),
              minHeight: 5,
            ),
          Expanded(
            child: _step == 5 ? _buildDoneScreen() : _buildWizardScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildWizardScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 90,
            height: 90,
            decoration: BoxDecoration(
                color: _stepColor.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(_stepIcon, color: _stepColor, size: 44),
          ),
          const SizedBox(height: 20),
          Text(_stepTitle,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A3C38)),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(_stepHint,
              style: const TextStyle(
                  fontSize: 14, color: Colors.grey, height: 1.6),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          if (_isSpeaking)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                  color: const Color(0xFF135C52).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(30)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.graphic_eq, color: Color(0xFF135C52), size: 18),
                SizedBox(width: 8),
                Text('Speaking...',
                    style: TextStyle(
                        color: Color(0xFF135C52),
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          if (_isListening) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(30)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.mic, color: Color(0xFFE74C3C), size: 18),
                SizedBox(width: 8),
                Text('Listening...',
                    style: TextStyle(
                        color: Color(0xFFE74C3C),
                        fontWeight: FontWeight.w600)),
              ]),
            ),
            if (_listenedWords.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('"$_listenedWords"',
                  style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF1A3C38))),
            ],
          ],
          const SizedBox(height: 30),
          if (_reportType != null)
            _summaryCard(Icons.report_problem, 'Problem', _reportType!,
                const Color(0xFFE74C3C)),
          if (_location != null)
            _summaryCard(Icons.location_on, 'Location', _location!,
                const Color(0xFF135C52)),
          if (_crowdedSpot.isNotEmpty)
            _summaryCard(Icons.people, 'Crowded Spot', _crowdedSpot,
                const Color(0xFF7B8FF7)),
          const SizedBox(height: 30),
          if (!_isListening && !_isSpeaking) ...[
            GestureDetector(
              onTap: () {
                if (_step == 0) {
                  _askProblemType();
                } else if (_step == 1) _askProblemType();
                else if (_step == 2) _askLocation();
                else if (_step == 3) _askCrowdedSpot();
                else if (_step == 4) _askConfirm();
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _stepColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: _stepColor.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 4)
                  ],
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 48),
              ),
            ),
            const SizedBox(height: 14),
            Text(_step == 0 ? 'Tap to Begin' : 'Tap to Answer',
                style: TextStyle(
                    color: _stepColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
          if (_step == 1 && !_isListening && !_isSpeaking) ...[
            const SizedBox(height: 24),
            const Text('— or tap a type below —',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _reportTypes.map((r) {
                bool sel = _reportType == r['type'];
                Color c = r['color'] as Color;
                return GestureDetector(
                  onTap: () async {
                    setState(() => _reportType = r['type'] as String);
                    await _speak('${r['type']} selected.');
                    await _askLocation();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                        color: sel ? c : c.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: c.withOpacity(0.4))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(r['icon'] as IconData,
                          color: sel ? Colors.white : c, size: 16),
                      const SizedBox(width: 6),
                      Text(r['type'] as String,
                          style: TextStyle(
                              color: sel ? Colors.white : c,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _summaryCard(
      IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Row(children: [
        Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: color)),
        ]),
      ]),
    );
  }

  Widget _buildDoneScreen() {
    if (_isSubmitting) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularProgressIndicator(color: Color(0xFF135C52)),
          SizedBox(height: 20),
          Text('Submitting your report...',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
        ]),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                  color: const Color(0xFF135C52).withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.check_circle,
                  color: Color(0xFF135C52), size: 60)),
          const SizedBox(height: 24),
          const Text('Report Submitted!',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A3C38))),
          const SizedBox(height: 16),
          if (_reportType != null)
            _summaryCard(Icons.report_problem, 'Problem', _reportType!,
                const Color(0xFFE74C3C)),
          if (_location != null)
            _summaryCard(Icons.location_on, 'Location', _location!,
                const Color(0xFF135C52)),
          if (_crowdedSpot.isNotEmpty)
            _summaryCard(Icons.people, 'Crowded Spot', _crowdedSpot,
                const Color(0xFF7B8FF7)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _reportType = null;
                  _location = null;
                  _crowdedSpot = '';
                });
                _startWizard();
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Report Another Problem',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135C52),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Home',
                  style: TextStyle(
                      color: Color(0xFF135C52),
                      fontWeight: FontWeight.w600))),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _stt.stop();
    super.dispose();
  }
}