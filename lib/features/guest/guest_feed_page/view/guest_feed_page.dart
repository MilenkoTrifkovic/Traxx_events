import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/features/guest/guest_feed_page/controller/guest_feed_controller.dart';
import 'package:traxx_wepapp/features/guest/guest_feed_page/widgets/feed_header.dart';
import 'package:traxx_wepapp/features/guest/guest_feed_page/widgets/message_input_bar.dart';
import 'package:traxx_wepapp/features/guest/guest_feed_page/widgets/message_list_widget.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';

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
      backgroundColor: Colors.white, // White outer area
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
        // Feed Header with spacing
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: _buildResponsiveHeader(context, isPhone, isTablet),
        ),
        // Messages list with spacing
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
            child: _buildResponsiveContent(
                context, controller, isPhone, isTablet),
          ),
        ),
        // Message input bar with spacing
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child:
              _buildResponsiveInputBar(context, controller, isPhone, isTablet),
        ),
      ],
    );
  }

  Widget _buildResponsiveHeader(
    BuildContext context,
    bool isPhone,
    bool isTablet,
  ) {
    final header = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FeedHeader(
        eventName: eventName,
      ),
    );

    // For desktop/tablet, center the header with max width
    if (!isPhone) {
      return Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 700 : 800,
          ),
          child: header,
        ),
      );
    }

    // For phone, use full width
    return header;
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
          onRemoveFile: controller.removeFileAt,
          isEnabled: !controller.isSending.value,
          isSending: controller.isSending.value,
          hintText: 'Share your thoughts...',
          selectedFileNames: controller.selectedFileNames.toList(),
          selectedFileTypes: controller.selectedFileTypes.toList(),
          selectedFiles: controller.selectedFiles.toList(),
        ));

    final wrappedInputBar = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: inputBar,
    );

    // For desktop/tablet, center the input bar with max width
    if (!isPhone) {
      return Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 700 : 800,
          ),
          child: wrappedInputBar,
        ),
      );
    }

    // For phone, use full width
    return wrappedInputBar;
  }

  Widget _buildResponsiveContent(
    BuildContext context,
    GuestFeedController controller,
    bool isPhone,
    bool isTablet,
  ) {
    final content = MessageListWidget(
      messages: controller.messages,
      scrollController: controller.scrollController,
      isLoading: controller.isLoading,
      isLoadingMore: controller.isLoadingMore,
      isMyMessage: controller.isMyMessage,
    );

    final wrappedContent = Container(
      decoration: BoxDecoration(
        color: Colors.white, // White background to match other sections
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: content,
      ),
    );

    // For desktop/tablet, center the content with max width
    if (!isPhone) {
      return Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 700 : 800,
          ),
          child: wrappedContent,
        ),
      );
    }

    // For phone, use full width
    return wrappedContent;
  }
}
