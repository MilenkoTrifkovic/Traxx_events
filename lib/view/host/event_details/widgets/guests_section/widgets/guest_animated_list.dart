import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/host_controllers/guests_controllers/set_guests_controller.dart';
import 'package:traxx_wepapp/view/host/event_details/widgets/guests_section/widgets/guest_list_item.dart';

/// A widget that displays an animated list of guests with smooth entry and exit animations.
/// Uses [AnimatedList] for fluid animations and [GuestListItem] for individual guest display.
/// Supports custom scroll control and color mapping for list items.
class GuestAnimatedList extends StatelessWidget {
  final GlobalKey<AnimatedListState> listKey;
  final ScrollController scrollController;
  final Map<int, Color> colors;

  GuestAnimatedList(
      {super.key,
      required this.listKey,
      required this.scrollController,
      required this.colors});
  final SetGuestsController setGuestsController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedList(
        controller: scrollController,
        key: listKey,
        initialItemCount: setGuestsController.guests.length,
        itemBuilder: (context, index, animation) {
          return GuestListItem(
            key: UniqueKey(),
            color: colors[index],
            index: index,
            item: setGuestsController.guests[index],
            animation: animation,
            onPressed: (index) {
              _removeItem(index);
            },
          );
        },
      ),
    );
  }

  void _removeItem(int index) async {
    final removedItem = await setGuestsController.removeGuest(index);
    listKey.currentState?.removeItem(
      index,
      (context, animation) => GuestListItem(
        index: index,
        onPressed: _removeItem,
        item: removedItem,
        animation: animation,
      ),
    );
  }
}
