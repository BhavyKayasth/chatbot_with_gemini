import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:chatbot_with_gemini/models/message_model.dart';

class MyMessageWidget extends StatelessWidget {
  const MyMessageWidget({
    super.key,
    required this.message,
  });

  final Message message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = theme.colorScheme.primaryContainer;
    final textColor = theme.colorScheme.onPrimaryContainer;

    final hasImage = message.imagesUrls.isNotEmpty;
    final hasText = message.message.toString().trim().isNotEmpty;

    return Align(
      alignment: Alignment.centerRight,
      child: hasImage
      // ✅ Case 1: Image (with/without text)
          ? Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.file(
                File(message.imagesUrls.first),
                fit: BoxFit.cover,
                height: 200,
                width: double.infinity,
              ),
            ),
            if (hasText)
              Padding(
                padding: const EdgeInsets.all(14),
                child: MarkdownBody(
                  selectable: true,
                  data: message.message.toString().trim(),
                  styleSheet: MarkdownStyleSheet(
                    p: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                  ),
                ),
              ),
          ],
        ),
      )

      // ✅ Case 2: Text only (auto-adjust width)
          : Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 40,
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          child: IntrinsicWidth(
            child: MarkdownBody(
              selectable: true,
              data: message.message.toString().trim(),
              styleSheet: MarkdownStyleSheet(
                p: theme.textTheme.bodyMedium?.copyWith(color: textColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
