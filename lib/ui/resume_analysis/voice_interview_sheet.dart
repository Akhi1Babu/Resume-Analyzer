part of 'analysis_page.dart';

// You will need to import speech_to_text and flutter_tts in analysis_page.dart

class _VoiceInterviewSheet extends StatefulWidget {
  final String resumeText;
  final ResumeService resumeService;

  const _VoiceInterviewSheet({
    required this.resumeText,
    required this.resumeService,
  });

  @override
  State<_VoiceInterviewSheet> createState() => _VoiceInterviewSheetState();
}

class _VoiceInterviewSheetState extends State<_VoiceInterviewSheet>
    with SingleTickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  final TextEditingController _textCtrl = TextEditingController();

  final List<Map<String, String>> _history = [];

  bool _isSpeechInitialized = false;
  bool _isListening = false;
  bool _isThinking = false;
  bool _isSpeaking = false;

  String _aiLatestResponse = 'Press Start to begin the interview.';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initSpeechAndTTS();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initSpeechAndTTS() async {
    try {
      _isSpeechInitialized = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (_isListening && mounted) {
              setState(() => _isListening = false);
            }
          }
        },
        onError: (errorNotification) {
          debugPrint('Speech error: \${errorNotification.errorMsg}');
          if (mounted) setState(() => _isListening = false);
        },
      );

      await _flutterTts.setLanguage("en-US");

      // Get all available voices to try and pick a more natural "human" female one
      final voices = await _flutterTts.getVoices;
      if (voices != null) {
        List<dynamic> voicesList = List<dynamic>.from(voices);

        // Define an ordered list of high-quality female voice keywords
        final preferredFemaleVoices = [
          'jenny', // Microsoft Jenny Online (Natural)
          'aria', // Microsoft Aria Online (Natural)
          'samantha', // Apple Samantha
          'karen', // Apple Karen
          'melina', // Apple Melina
          'google us english', // Standard Chrome female voice
          'zira', // Microsoft Zira (acceptable Windows fallback)
        ];

        bool voiceFound = false;
        for (String preferred in preferredFemaleVoices) {
          for (var voice in voicesList) {
            String name = voice["name"].toString().toLowerCase();
            String locale = voice["locale"].toString().toLowerCase();
            if (name.contains(preferred) && locale.contains('en')) {
              await _flutterTts.setVoice({
                "name": voice["name"],
                "locale": voice["locale"],
              });
              voiceFound = true;
              break;
            }
          }
          if (voiceFound) break;
        }
      }

      await _flutterTts.setSpeechRate(0.9); // Normal conversational speed
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0); // 1.0 is default human pitch

      _flutterTts.setStartHandler(() {
        if (mounted) setState(() => _isSpeaking = true);
      });

      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() => _isSpeaking = false);
        }
      });

      _flutterTts.setErrorHandler((msg) {
        if (mounted) setState(() => _isSpeaking = false);
      });
    } catch (e) {
      debugPrint("Error initializing speech/tts: $e");
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flutterTts.stop();
    _speechToText.stop();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _startInterview() async {
    setState(() {
      _isThinking = true;
      _aiLatestResponse = "Analyzing resume to prepare first question...";
    });

    try {
      final reply = await widget.resumeService.voiceInterviewTurn(
        resumeText: widget.resumeText,
        history: [],
        userMessage: "",
      );

      if (!mounted) return;
      setState(() {
        _history.add({'role': 'model', 'text': reply});
        _aiLatestResponse = reply;
        _isThinking = false;
      });
      _speak(reply);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isThinking = false;
        _aiLatestResponse = "Error starting interview. Try again.";
      });
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> _startListening() async {
    await _flutterTts.stop(); // Stop anything currently playing
    if (!_isSpeechInitialized) {
      final initialized = await _speechToText.initialize();
      if (!initialized) {
        setState(() => _aiLatestResponse = "Microphone access denied.");
        return;
      }
      _isSpeechInitialized = true;
    }

    setState(() {
      _isListening = true;
      _textCtrl.text = '';
      _isSpeaking = false;
    });

    await _speechToText.listen(
      onResult: (result) {
        if (mounted) {
          setState(() {
            _textCtrl.text = result.recognizedWords;
          });
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.dictation,
    );
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  Future<void> _sendResponse() async {
    final msg = _textCtrl.text.trim();
    if (msg.isEmpty) return;

    if (_isListening) await _stopListening();
    await _flutterTts.stop();

    setState(() {
      _history.add({'role': 'user', 'text': msg});
      _textCtrl.clear();
      _isThinking = true;
      _aiLatestResponse = "Thinking...";
    });

    try {
      final reply = await widget.resumeService.voiceInterviewTurn(
        resumeText: widget.resumeText,
        history: List.from(_history),
        userMessage: msg,
      );

      if (!mounted) return;
      setState(() {
        _history.add({'role': 'model', 'text': reply});
        _aiLatestResponse = reply;
        _isThinking = false;
      });
      _speak(reply);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isThinking = false;
        _aiLatestResponse = "Connection error. Let's try your answer again.";
        // Pop the user's failed message so they can re-try
        _history.removeLast();
        _textCtrl.text = msg; // Put text back
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colors
    const primary = Color(0xFF00B4FF);
    const surface = Color(0xFF1E1E35);
    const bg = Color(0xFF12121F);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.record_voice_over,
                        color: primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🎙️ Realtime Voice Interview',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'AI Recruiter will ask based on your resume',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.headphones, color: Colors.white70),
                      tooltip: 'Change Microphone (Bluetooth)',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1E1E35),
                            title: const Text(
                              'Using Bluetooth Devices',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: const Text(
                              "Since this app runs securely in your browser, it uses your browser's default microphone.\n\n"
                              "To switch to a Bluetooth headset or external mic:\n"
                              "1. Check your browser address bar (top of screen).\n"
                              "2. Click the Camera/Microphone icon or Site Settings icon.\n"
                              "3. Select your preferred Microphone from the dropdown list.\n"
                              "4. Refresh or click allow if prompted.",
                              style: TextStyle(
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Got it',
                                  style: TextStyle(color: Color(0xFF00B4FF)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(color: Colors.white.withOpacity(0.08)),
              ],
            ),
          ),

          // Main Area - Scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // AI Avatar / status
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isSpeaking ? primary.withOpacity(0.15) : surface,
                      boxShadow: _isSpeaking
                          ? [
                              BoxShadow(
                                color: primary.withOpacity(0.3),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      _isThinking
                          ? Icons.more_horiz
                          : _isSpeaking
                          ? Icons.waves
                          : Icons.psychology_alt,
                      size: 64,
                      color: _isSpeaking ? primary : Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // AI Text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      _aiLatestResponse,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Start Button (If Not Started)
                  if (_history.isEmpty &&
                      !_isThinking &&
                      !_isListening &&
                      !_isSpeaking)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _startInterview,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text(
                          'Start Interview',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Controls
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.07)),
              ),
            ),
            child: Row(
              children: [
                // Text Input / Voice Output Box
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isListening
                            ? Colors.redAccent.withOpacity(0.5)
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _textCtrl,
                            enabled: _history.isNotEmpty && !_isThinking,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: _isListening
                                  ? 'Listening...'
                                  : 'Type or speak your answer...',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                              ),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _sendResponse(),
                          ),
                        ),
                        // Voice Button inside text field to act as a clear dictation trigger
                        if (_history.isNotEmpty)
                          GestureDetector(
                            onTap: _isListening
                                ? _stopListening
                                : _startListening,
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _isListening
                                      ? _pulseAnimation.value
                                      : 1.0,
                                  child: Container(
                                    margin: const EdgeInsets.all(6),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _isListening
                                          ? Colors.redAccent
                                          : Colors.white12,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isListening ? Icons.stop : Icons.mic,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Send Button
                Container(
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: (_history.isNotEmpty && !_isThinking)
                        ? _sendResponse
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
