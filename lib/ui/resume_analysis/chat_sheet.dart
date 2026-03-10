part of 'analysis_page.dart';

class _ChatSheetState extends State<_ChatSheet> {
  final List<Map<String, String>> _history = [];
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _listScroll = ScrollController();
  bool _isLoading = false;

  static const _suggestions = [
    'What are my strongest skills?',
    'What should I improve first?',
    'Am I ready for a senior role?',
    'What keywords am I missing?',
    'How does my experience stand out?',
  ];

  @override
  void dispose() {
    _inputCtrl.dispose();
    _listScroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final msg = text.trim();
    if (msg.isEmpty || _isLoading) return;
    _inputCtrl.clear();
    setState(() {
      _history.add({'role': 'user', 'text': msg});
      _isLoading = true;
    });
    _scrollToBottom();
    try {
      final reply = await widget.resumeService.chatWithResume(
        resumeText: widget.resumeText,
        history: List.from(_history.sublist(0, _history.length - 1)),
        userMessage: msg,
      );
      setState(() => _history.add({'role': 'model', 'text': reply}));
    } catch (e) {
      setState(
        () => _history.add({
          'role': 'model',
          'text': 'Sorry, I ran into an error. Please try again.',
        }),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listScroll.hasClients) {
        _listScroll.animateTo(
          _listScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF12121F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
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
                        color: const Color(0xFF00FFC2).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.smart_toy_outlined,
                        color: Color(0xFF00FFC2),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '💬 Chat with Your Resume',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Ask anything — our AI career coach answers',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(color: Colors.white.withOpacity(0.08)),
              ],
            ),
          ),

          // ── Message list ─────────────────────────────────────────────
          Expanded(
            child: _history.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _listScroll,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: _history.length + (_isLoading ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (_isLoading && i == _history.length) {
                        return _buildTypingIndicator();
                      }
                      final msg = _history[i];
                      return _buildBubble(
                        msg['text'] ?? '',
                        msg['role'] == 'user',
                      );
                    },
                  ),
          ),

          // ── Input row ────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
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
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _send,
                    decoration: InputDecoration(
                      hintText: 'Ask about your resume…',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _send(_inputCtrl.text),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _isLoading
                          ? Colors.white12
                          : const Color(0xFF00FFC2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: _isLoading
                          ? Colors.white38
                          : const Color(0xFF0F0F1E),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 16),
        const Center(
          child: Text(
            '👇 Tap a suggestion or type your question',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _suggestions.map((s) {
            return GestureDetector(
              onTap: () => _send(s),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FFC2).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00FFC2).withOpacity(0.28),
                  ),
                ),
                child: Text(
                  s,
                  style: const TextStyle(
                    color: Color(0xFF00FFC2),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 10,
          left: isUser ? 52 : 0,
          right: isUser ? 0 : 52,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF00FFC2).withOpacity(0.14)
              : const Color(0xFF1E1E35),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: Border.all(
            color: isUser
                ? const Color(0xFF00FFC2).withOpacity(0.3)
                : Colors.white.withOpacity(0.07),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser
                ? const Color(0xFF00FFC2)
                : Colors.white.withOpacity(0.88),
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(0),
            const SizedBox(width: 5),
            _dot(200),
            const SizedBox(width: 5),
            _dot(400),
          ],
        ),
      ),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.25, end: 1.0),
      duration: Duration(milliseconds: 600 + delayMs),
      curve: Curves.easeInOut,
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF00FFC2),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
