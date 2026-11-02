import 'package:abm_madrasa/core/theme/app_theme.dart';
import 'package:abm_madrasa/features/assistant/services/erp_ai_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Shows the Madrasa ERP AI Assistant modal or dialog depending on screen size.
void showErpAssistantModal(BuildContext context) {
  if (context.isDesktop) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => const Dialog(
        alignment: Alignment.bottomRight,
        insetPadding: EdgeInsets.only(right: 24, bottom: 24, top: 60),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: SizedBox(
          width: 440,
          height: 620,
          child: ErpAssistantChatView(),
        ),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const FractionallySizedBox(
        heightFactor: 0.90,
        child: ErpAssistantChatView(),
      ),
    );
  }
}

class ErpAssistantChatView extends StatefulWidget {
  const ErpAssistantChatView({super.key});

  @override
  State<ErpAssistantChatView> createState() => _ErpAssistantChatViewState();
}

class _ErpAssistantChatViewState extends State<ErpAssistantChatView> {
  final _aiService = ErpAiService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  final List<String> _quickSuggestions = [
    '📝 How to mark attendance?',
    '🗓️ How does the Shift Planner work?',
    '📖 How to record Hifz Sabaq?',
    '📋 How to assign homework?',
    '📊 How to enter exam marks?',
    '📑 How to add progress reports?',
    '💾 How to download backup?',
    '💰 Where to see unpaid fees?',
    '🚌 How to manage transport?',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        id: 'welcome',
        role: 'model',
        text:
            "**Assalamu Alaikum!** I am your Anas Bin Malik Madrasa ERP assistant.\n\nAsk me anything about using the system—attendance, Quran Hifz, homework, exams, student records, fees, or data backup!",
        timestamp: DateTime.now(),
        actions: [
          const AssistantAction(route: '/attendance', label: 'Attendance'),
          const AssistantAction(route: '/hifz', label: 'Hifz Tracker'),
          const AssistantAction(route: '/homework', label: 'Homework'),
        ],
      ),
    );
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
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  Future<void> _handleSend([String? presetText]) async {
    final text = (presetText ?? _textController.text).trim();
    if (text.isEmpty || _isLoading) return;

    _textController.clear();

    setState(() {
      _messages.add(
        ChatMessage(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          role: 'user',
          text: text,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final reply = await _aiService.sendMessage(text);
      if (mounted) {
        setState(() {
          _messages.add(reply);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              id: 'err_${DateTime.now().millisecondsSinceEpoch}',
              role: 'model',
              text:
                  "I encountered an error reaching the server, but I am still available offline. Please ask your question again.",
              timestamp: DateTime.now(),
              isError: true,
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _clearChat() {
    _aiService.clearHistory();
    setState(() {
      _messages.clear();
      _messages.add(
        ChatMessage(
          id: 'welcome_reset',
          role: 'model',
          text: "Chat cleared! How can I assist you with Madrasa ERP today?",
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          _buildHeader(context),

          // Quick Suggestion Chips (if few messages)
          if (_messages.length <= 3) _buildSuggestionChips(context),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(context, _messages[index]);
              },
            ),
          ),

          // Typing Indicator
          if (_isLoading) _buildTypingIndicator(context),

          // Input Bar
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: colors.primary,
        border: Border(
          bottom: BorderSide(color: colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.secondary.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(color: colors.secondary.withValues(alpha: 0.6)),
            ),
            child: Icon(
              LucideIcons.sparkles,
              color: colors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Madrasa Assistant',
                        style: context.typography.bodyLargeSemiBold.copyWith(
                          color: colors.white,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.secondary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'AI',
                        style: context.typography.caption.copyWith(
                          color: colors.secondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Instant guide for teachers & staff',
                  style: context.typography.bodySmall.copyWith(
                    color: colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Clear conversation',
            child: IconButton(
              icon: Icon(
                LucideIcons.rotateCcw,
                color: colors.white.withValues(alpha: 0.75),
                size: 18,
              ),
              onPressed: _clearChat,
            ),
          ),
          IconButton(
            icon: Icon(
              LucideIcons.x,
              color: colors.white.withValues(alpha: 0.85),
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: colors.border.withValues(alpha: 0.5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.helpCircle, size: 13, color: colors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Frequently Asked Questions:',
                style: context.typography.caption.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickSuggestions.map((q) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(q),
                    labelStyle: context.typography.bodySmall.copyWith(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    backgroundColor: colors.white,
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onPressed: () => _handleSend(q),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage msg) {
    final colors = context.colors;
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.sparkles,
                size: 15,
                color: colors.secondary,
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? colors.primary
                        : colors.cardBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isUser
                          ? colors.primary
                          : colors.border.withValues(alpha: 0.8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildFormattedText(
                    context,
                    msg.text,
                    isUser ? colors.white : colors.textPrimary,
                  ),
                ),
                // Deep Link Action Buttons
                if (!isUser && msg.actions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: msg.actions.map((act) {
                      return ElevatedButton.icon(
                        icon: const Icon(LucideIcons.arrowUpRight, size: 14),
                        label: Text(act.label),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.white,
                          foregroundColor: colors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          side: BorderSide(
                            color: colors.secondary.withValues(alpha: 0.8),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: context.typography.bodySmallSemiBold.copyWith(
                            fontSize: 12,
                          ),
                        ),
                        onPressed: () {
                          // Close dialog and navigate
                          Navigator.of(context).pop();
                          context.go(act.route);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: colors.secondary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: colors.secondary),
              ),
              child: Icon(
                LucideIcons.user,
                size: 15,
                color: colors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Simple rich text parser for bold `**` and line breaks
  Widget _buildFormattedText(
      BuildContext context, String text, Color defaultColor) {
    final lines = text.split('\n');
    final spans = <InlineSpan>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final regex = RegExp(r'\*\*(.*?)\*\*');
      int lastIndex = 0;

      for (final match in regex.allMatches(line)) {
        if (match.start > lastIndex) {
          spans.add(
            TextSpan(
              text: line.substring(lastIndex, match.start),
              style: TextStyle(color: defaultColor, fontSize: 13.5, height: 1.45),
            ),
          );
        }
        spans.add(
          TextSpan(
            text: match.group(1),
            style: TextStyle(
              color: defaultColor,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        );
        lastIndex = match.end;
      }

      if (lastIndex < line.length) {
        spans.add(
          TextSpan(
            text: line.substring(lastIndex),
            style: TextStyle(color: defaultColor, fontSize: 13.5, height: 1.45),
          ),
        );
      }

      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Gemini is typing...',
                  style: context.typography.bodySmall.copyWith(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: colors.white,
        border: Border(
          top: BorderSide(color: colors.border.withValues(alpha: 0.8)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colors.border),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                style: TextStyle(color: colors.textPrimary, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Ask how to do anything in the ERP...',
                  hintStyle: TextStyle(
                    color: colors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : () => _handleSend(),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _isLoading
                      ? colors.primary.withValues(alpha: 0.5)
                      : colors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.send,
                  color: colors.white,
                  size: 17,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
