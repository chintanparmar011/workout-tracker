import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ai_coach_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/ai_message_model.dart';
import '../../utils/api_constants.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<AiCoachProvider>().loadChatHistory(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? prefilledText]) {
    final text = prefilledText ?? _textController.text;
    if (text.trim().isEmpty) return;

    final userProfile = context.read<AuthProvider>().userProfile;
    final userId = context.read<AuthProvider>().user?.uid;
    final aiProvider = context.read<AiCoachProvider>();

    if (prefilledText == null) {
      _textController.clear();
    }

    aiProvider.sendMessage(text, userProfile: userProfile, userId: userId);
    _scrollToBottom();
  }

  void _showApiKeyDialog() {
    final aiProvider = context.read<AiCoachProvider>();
    final controller = TextEditingController(
      text: aiProvider.customApiKey ??
          (ApiConstants.geminiApiKey.isNotEmpty ? ApiConstants.geminiApiKey : ''),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.vpn_key, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text('Gemini API Key'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OmniFit AI Coach uses Google Gemini 2.5 Flash for real-time fitness intelligence. You can get a free key at:',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 6),
            const SelectableText(
              'https://aistudio.google.com/',
              style: TextStyle(
                color: Colors.deepOrange,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'If left blank, OmniFit automatically uses its built-in offline fitness expert engine.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Google AI Studio API Key',
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              aiProvider.setCustomApiKey('');
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reverted to built-in fitness engine')),
              );
            },
            child: const Text('Use Default'),
          ),
          ElevatedButton(
            onPressed: () {
              aiProvider.setCustomApiKey(controller.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gemini API key updated successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save Key'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = context.watch<AiCoachProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OmniFit AI Coach',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Fitness & Nutrition Specialist',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key_outlined),
            tooltip: 'Configure Gemini API Key',
            onPressed: _showApiKeyDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Clear Chat',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Conversation?'),
                  content: const Text('This will reset your current AI coaching chat.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        final uid = context.read<AuthProvider>().user?.uid;
                        aiProvider.clearChat(uid);
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Suggestion Chips Bar
            Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: aiProvider.suggestionChips.map((chipText) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: const Icon(
                          Icons.chat_bubble_outline,
                          size: 14,
                          color: Colors.deepOrange,
                        ),
                        label: Text(
                          chipText,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.deepOrange.withValues(alpha: 0.08),
                        side: BorderSide(
                          color: Colors.deepOrange.withValues(alpha: 0.3),
                        ),
                        onPressed: aiProvider.isLoading
                            ? null
                            : () => _sendMessage(chipText),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(height: 1),

            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: aiProvider.messages.length + (aiProvider.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == aiProvider.messages.length && aiProvider.isLoading) {
                    return _buildThinkingBubble();
                  }
                  final msg = aiProvider.messages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),

            // Input Bar
            _buildInputBar(aiProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.deepOrange.withValues(alpha: 0.15),
            child: const Icon(Icons.fitness_center, size: 18, color: Colors.deepOrange),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'OmniFit Coach is preparing your fitness advice...',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AiMessageModel msg) {
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.deepOrange.withValues(alpha: 0.15),
              child: const Icon(Icons.psychology, size: 18, color: Colors.deepOrange),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser
                    ? Colors.deepOrange
                    : (msg.isError ? Colors.red.shade50 : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: msg.isError
                            ? Colors.red.shade200
                            : Colors.grey.shade300,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildFormattedText(msg.content, isUser),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.deepOrange.shade100,
              child: const Icon(Icons.person, size: 18, color: Colors.deepOrange),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormattedText(String text, bool isUser) {
    if (isUser) {
      return Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    // Clean formatting for headers and bullets
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();

        if (trimmed.startsWith('### ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text(
              trimmed.replaceFirst('### ', ''),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          );
        }

        if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
          final content = trimmed.substring(2);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                    fontSize: 16,
                  ),
                ),
                Expanded(
                  child: _buildSpans(content),
                ),
              ],
            ),
          );
        }

        if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
          final match = RegExp(r'^\d+\.\s').firstMatch(trimmed)!;
          final prefix = match.group(0)!;
          final content = trimmed.substring(prefix.length);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prefix,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                    fontSize: 14,
                  ),
                ),
                Expanded(
                  child: _buildSpans(content),
                ),
              ],
            ),
          );
        }

        if (trimmed.isEmpty) {
          return const SizedBox(height: 6);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: _buildSpans(trimmed),
        );
      }).toList(),
    );
  }

  Widget _buildSpans(String raw) {
    // Basic bold parsing for **bold**
    final parts = raw.split('**');
    if (parts.length <= 1) {
      return Text(
        raw,
        style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
      );
    }

    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      final isBold = i % 2 == 1;
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black87 : Colors.black87,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildInputBar(AiCoachProvider aiProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Ask about diet, muscle growth, workouts...',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: aiProvider.isLoading ? Colors.grey : Colors.deepOrange,
            radius: 22,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: aiProvider.isLoading ? null : () => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }
}
