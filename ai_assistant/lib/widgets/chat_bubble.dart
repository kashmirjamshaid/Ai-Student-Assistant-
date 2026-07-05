import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../constants/app_colors.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isBookmarked;
  final VoidCallback onCopy;
  final VoidCallback onBookmark;
  final VoidCallback? onRegenerate;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isBookmarked,
    required this.onCopy,
    required this.onBookmark,
    this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Bubble content
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                // AI Avatar
                Container(
                  margin: const EdgeInsets.only(right: 8.0, top: 4.0),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 16.0,
                  ),
                ),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: isUser 
                        ? theme.colorScheme.primary.withOpacity(0.9) 
                        : theme.cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20.0),
                      topRight: const Radius.circular(20.0),
                      bottomLeft: isUser ? const Radius.circular(20.0) : const Radius.circular(4.0),
                      bottomRight: isUser ? const Radius.circular(4.0) : const Radius.circular(20.0),
                    ),
                    boxShadow: isUser
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                    border: isUser
                        ? null
                        : Border.all(
                            color: theme.dividerColor.withOpacity(0.05),
                            width: 1.0,
                          ),
                  ),
                  child: isUser
                      ? Text(
                          message.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.0,
                            height: 1.4,
                          ),
                        )
                      : MarkdownBody(
                          data: message.text,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                            p: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 15.0,
                              height: 1.5,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                            h1: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.0,
                              height: 1.8,
                            ),
                            h2: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                              height: 1.6,
                            ),
                            listBullet: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                            code: TextStyle(
                              backgroundColor: theme.dividerColor.withOpacity(0.1),
                              fontFamily: 'monospace',
                              fontSize: 13.0,
                              color: theme.colorScheme.secondary,
                            ),
                            codeblockPadding: const EdgeInsets.all(12.0),
                            codeblockDecoration: BoxDecoration(
                              color: theme.dividerColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                ),
              ),
              if (isUser) ...[
                // User Avatar
                Container(
                  margin: const EdgeInsets.only(left: 8.0, top: 4.0),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: theme.colorScheme.secondary,
                    size: 16.0,
                  ),
                ),
              ],
            ],
          ),
          // Action Buttons beneath AI Messages
          if (!isUser) ...[
            Padding(
              padding: const EdgeInsets.only(left: 40.0, top: 4.0),
              child: Row(
                children: [
                  _ActionButton(
                    icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    label: isBookmarked ? "Bookmarked" : "Bookmark",
                    iconColor: isBookmarked ? theme.colorScheme.primary : null,
                    onTap: onBookmark,
                  ),
                  const SizedBox(width: 8.0),
                  _ActionButton(
                    icon: Icons.copy_rounded,
                    label: "Copy",
                    onTap: onCopy,
                  ),
                  if (onRegenerate != null) ...[
                    const SizedBox(width: 8.0),
                    _ActionButton(
                      icon: Icons.refresh_rounded,
                      label: "Regenerate",
                      onTap: onRegenerate!,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16.0,
              color: iconColor ?? theme.textTheme.bodySmall?.color?.withOpacity(0.5),
            ),
            const SizedBox(width: 4.0),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.0,
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
