import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/features/guest/guest_feed_page/widgets/message_bubble.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/models/message.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

/// Widget that displays a list of messages in the feed
class MessageListWidget extends StatelessWidget {
  final RxList<Message> messages;
  final ScrollController? scrollController;
  final RxBool isLoading;
  final RxBool isLoadingMore;
  final bool Function(String userId) isMyMessage;

  const MessageListWidget({
    super.key,
    required this.messages,
    this.scrollController,
    required this.isLoading,
    required this.isLoadingMore,
    required this.isMyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);

    return Obx(() {
      if (isLoading.value && messages.isEmpty) {
        return Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryAccent,
          ),
        );
      }

      if (messages.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: isPhone ? 48 : 64,
                color: AppColors.textMuted,
              ),
              AppSpacing.verticalMd(context),
              AppText.styledBodyMedium(
                context,
                'No messages yet',
                color: AppColors.textMuted,
              ),
              AppSpacing.verticalXs(context),
              AppText.styledBodySmall(
                context,
                'Be the first to start the conversation',
                color: AppColors.textMuted,
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        controller: scrollController,
        reverse: true, // Show newest messages at bottom
        padding: EdgeInsets.all(AppSpacing.md(context)),
        itemCount: messages.length + 1, // +1 for loading indicator
        separatorBuilder: (context, index) {
          // No separator after loading indicator
          if (index == messages.length) return SizedBox.shrink();
          return AppSpacing.verticalSm(context);
        },
        itemBuilder: (context, index) {
          // Show loading indicator at the top (last item in reverse list)
          if (index == messages.length) {
            return Obx(() {
              if (!isLoadingMore.value) return SizedBox.shrink();
              
              return Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md(context)),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textMuted,
                        ),
                      ),
                      AppSpacing.verticalXs(context),
                      AppText.styledBodySmall(
                        context,
                        'Loading older messages...',
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              );
            });
          }

          final message = messages[index];
          final isOwn = isMyMessage(message.userId);
          return MessageBubble(
            message: message,
            isOwnMessage: isOwn,
          );
        },
      );
    });
  }
}
