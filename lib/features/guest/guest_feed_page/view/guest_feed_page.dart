import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/features/guest/guest_feed_page/controller/guest_feed_controller.dart';
import 'package:traxx_wepapp/features/guest/guest_feed_page/widgets/message_input_bar.dart';
import 'package:traxx_wepapp/features/guest/guest_feed_page/widgets/message_list_widget.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

/// Guest Feed Page - Displays event feed/comments
///
/// This page shows a real-time feed of messages for an event
/// and allows guests to post new messages.
class GuestFeedPage extends StatelessWidget {
  final String eventId;
  final String? eventName;

  const GuestFeedPage({
    super.key,
    required this.eventId,
    this.eventName,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final controller = Get.put(
      GuestFeedController(eventId: eventId),
      tag: eventId, // Use eventId as tag to support multiple instances
    );

    final isPhone = ScreenSize.isPhone(context);
    final isTablet = ScreenSize.isTablet(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: _buildBody(context, controller, isPhone, isTablet),
    );
  }

  Widget _buildBody(
    BuildContext context,
    GuestFeedController controller,
    bool isPhone,
    bool isTablet,
  ) {
    return Column(
      children: [
        // Divider
        Container(
          height: 1,
          color: AppColors.borderSubtle,
        ),
        // Messages list
        Expanded(
          child:
              _buildResponsiveContent(context, controller, isPhone, isTablet),
        ),
        // Message input bar with responsive constraints
        _buildResponsiveInputBar(context, controller, isPhone, isTablet),
      ],
    );
  }

  Widget _buildResponsiveInputBar(
    BuildContext context,
    GuestFeedController controller,
    bool isPhone,
    bool isTablet,
  ) {
    final inputBar = Obx(() => MessageInputBar(
          controller: controller.messageTextController,
          focusNode: controller.messageFocusNode,
          onSendMessage: (_) => controller.sendMessage(),
          onAttachFile: controller.selectPhoto,
          onRemoveFile: controller.removePhoto,
          isEnabled: !controller.isSending.value,
          isSending: controller.isSending.value,
          hintText: 'Share your thoughts...',
          selectedFileName: controller.selectedFileName.value,
          selectedFileType: controller.selectedFileType.value,
        ));

    // For desktop/tablet, center the input bar with max width
    if (!isPhone) {
      return Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 700 : 800,
          ),
          child: inputBar,
        ),
      );
    }

    // For phone, use full width
    return inputBar;
  }

  Widget _buildResponsiveContent(
    BuildContext context,
    GuestFeedController controller,
    bool isPhone,
    bool isTablet,
  ) {
    // For desktop/tablet, center the content with max width
    if (!isPhone) {
      return Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 700 : 800,
          ),
          child: MessageListWidget(
            messages: controller.messages,
            scrollController: controller.scrollController,
            isLoading: controller.isLoading,
            isLoadingMore: controller.isLoadingMore,
            isMyMessage: controller.isMyMessage,
          ),
        ),
      );
    }

    // For phone, use full width
    return MessageListWidget(
      messages: controller.messages,
      scrollController: controller.scrollController,
      isLoading: controller.isLoading,
      isLoadingMore: controller.isLoadingMore,
      isMyMessage: controller.isMyMessage,
    );
  }
}
