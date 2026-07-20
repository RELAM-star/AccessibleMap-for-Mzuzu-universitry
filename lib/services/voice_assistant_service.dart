// lib/services/voice_assistant_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceAssistantService {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  bool _isListening = false;
  bool _sttAvailable = false;

  bool get isListening => _isListening;

  // Callbacks
  Function(String)? onCommand;      // fired when user says something
  Function(bool)? onListeningChanged;

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    _tts.setErrorHandler((error) {});
    _sttAvailable = await _stt.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
          onListeningChanged?.call(false);
        }
      },
      onError: (error) {
        _isListening = false;
        onListeningChanged?.call(false);
      },
    );
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async => await _tts.stop();

  Future<void> startListening() async {
    if (!_sttAvailable) {
      await speak('Sorry, speech recognition is not available on this device.');
      return;
    }
    if (_isListening) return;
    await _tts.stop();
    _isListening = true;
    onListeningChanged?.call(true);
    await _stt.listen(
      onResult: (result) {
        if (result.finalResult) {
          _isListening = false;
          onListeningChanged?.call(false);
          final words = result.recognizedWords.toLowerCase().trim();
          if (words.isNotEmpty) onCommand?.call(words);
        }
      },
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  Future<void> stopListening() async {
    await _stt.stop();
    _isListening = false;
    onListeningChanged?.call(false);
  }

  void dispose() {
    _tts.stop();
    _stt.stop();
  }
}