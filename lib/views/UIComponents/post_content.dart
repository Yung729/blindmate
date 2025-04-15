import 'package:flutter/material.dart';

class PostContent extends StatelessWidget {
  final String content;
  final bool isExpanded;
  final int maxLinesCollapsed;
  final VoidCallback? onExpand;
  final VoidCallback? onCollapse;

  const PostContent({
    Key? key,
    required this.content,
    required this.isExpanded,
    required this.maxLinesCollapsed,
    this.onExpand,
    this.onCollapse,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: content, style: const TextStyle()),
          maxLines: maxLinesCollapsed,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final didExceed = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              maxLines: isExpanded ? null : maxLinesCollapsed,
              overflow: isExpanded ? TextOverflow.visible : TextOverflow.clip,
            ),
            if (didExceed && !isExpanded)
              const SizedBox(height: 4),
            if (didExceed && !isExpanded)
              GestureDetector(
                onTap: onExpand,
                child: const Text(
                  "See more",
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            if (isExpanded && didExceed)
              const SizedBox(height: 4),
            if (isExpanded && didExceed)
              GestureDetector(
                onTap: onCollapse,
                child: const Text(
                  "See less",
                  style: TextStyle(color: Colors.blue),
                ),
              ),
          ],
        );
      },
    );
  }
}