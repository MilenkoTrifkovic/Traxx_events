import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/controller/admin_controllers/admin_event_details_controllers/admin_event_details_controller.dart';
import 'package:traxx_wepapp/controller/admin_controllers/admin_event_details_controllers/menu_panel_controller.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/models/menu_model.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/loader.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets/menu_panel_item.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets/menu_selection_dialog.dart';

class MenuPanelBody extends StatelessWidget {
  final AdminEventDetailsController mainController;

  const MenuPanelBody({super.key, required this.mainController});

  Future<bool> _confirmRemoveItem(BuildContext context, String itemName) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text('Do you want to remove "$itemName" from this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return res == true;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final menus = mainController.availableMenus;
      final isMenusLoading = mainController.isMenusLoading.value;
      final selectedMenu = mainController.selectedMenu.value;
      final menuItems = mainController.menuItems;
      final isItemsLoading = mainController.isItemsLoading.value;
      final selectedItemIds = mainController.selectedMenuItemIds;
      final selMenuId = selectedMenu?.id;

      // 1. Loading state
      if (isMenusLoading) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      // 2. No menus yet → ask to create
      if (menus.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "No menus found for this organisation.",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Create at least one menu so you can attach it to this event.",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoute.hostMenus.path),
                icon: const Icon(Icons.add),
                label: const Text('Create Menu'),
              ),
            ],
          ),
        );
      }

      // 3. Menus exist → show everything
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------- HEADER -----------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Available Menus",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.push(AppRoute.hostMenus.path),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Menu'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // -------------- MENU CHIPS ----------------
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: menus.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) {
                  final m = menus[idx];
                  final isSel = selMenuId == m.id;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: ChoiceChip(
                      label: Text(
                        m.name,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      selected: isSel,
                      selectedColor: AppColors.primary.withOpacity(0.12),
                      backgroundColor: const Color(0xFFF3F4F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color:
                              isSel ? AppColors.primary : Colors.grey.shade300,
                        ),
                      ),
                      onSelected: (selected) async {
                        // Avoid re-calling API if already selected
                        if (!selected || isSel) return;
                        await mainController.chooseMenu(m);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ----------- SELECTED MENU CARD -----------
            if (selectedMenu == null) ...[
              Card(
                color: const Color(0xFFF9FAFB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: ListTile(
                  title: Text(
                    "No menu selected",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    "Choose one of your menus above to start adding dishes.",
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  trailing: TextButton(
                    child: const Text("Choose"),
                    onPressed: () {
                      // Focus user on chips – they are the chooser now
                      // You could optionally scroll here if needed.
                    },
                  ),
                ),
              ),
            ] else ...[
              Text(
                "Selected Menu",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: const Color(0xFFF9FAFB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  title: Text(
                    selectedMenu.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: (selectedMenu.description != null &&
                          selectedMenu.description!.isNotEmpty)
                      ? Text(
                          selectedMenu.description!,
                          style: GoogleFonts.poppins(fontSize: 13),
                        )
                      : null,
                  trailing: TextButton(
                    child: const Text("Change"),
                    onPressed: () {
                      // Changing is just picking another chip
                      // You could show a dialog again if you prefer,
                      // but chips already act as the selector.
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // -------------- MENU ITEMS ----------------
              if (isItemsLoading)
                const Center(child: CircularProgressIndicator())
              else if (menuItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "This menu has no items. Manage items on the menu page.",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              else ...[
                Text(
                  "Menu Items",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: menuItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final item = menuItems[index];
                    final isSelected =
                        selectedItemIds.contains(item.menuItemId);

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.7)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          item.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: (item.description != null &&
                                item.description!.isNotEmpty)
                            ? Text(
                                item.description!,
                                style: GoogleFonts.poppins(fontSize: 13),
                              )
                            : null,
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected
                                ? Colors.redAccent
                                : AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () async {
                            if (isSelected) {
                              final ok =
                                  await _confirmRemoveItem(context, item.name);
                              if (!ok) return;
                              await mainController.removeItemFromEvent(item);
                            } else {
                              await mainController.addItemToEvent(item);
                            }
                          },
                          child: Text(isSelected ? 'Remove' : 'Add'),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ],
        ),
      );
    });
  }
}

class MenuPickerDialog extends StatefulWidget {
  final List<MenuModel> menus;
  final MenuModel? initial;

  const MenuPickerDialog({super.key, required this.menus, this.initial});

  @override
  State<MenuPickerDialog> createState() => _MenuPickerDialogState();
}

class _MenuPickerDialogState extends State<MenuPickerDialog> {
  String search = '';
  MenuModel? selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.menus.where((m) {
      final q = search.trim().toLowerCase();
      if (q.isEmpty) return true;
      return m.name.toLowerCase().contains(q) ||
          (m.description ?? '').toLowerCase().contains(q);
    }).toList();

    return AlertDialog(
      title: Text('Select Menu',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search menus...',
              ),
              onChanged: (v) => setState(() => search = v),
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              const Text('No menus found', style: TextStyle(color: Colors.grey))
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final m = filtered[index];
                    final isSelected = selected?.id == m.id;
                    return ListTile(
                      leading: m.imageUrl != null && m.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(m.imageUrl!,
                                  width: 56, height: 56, fit: BoxFit.cover),
                            )
                          : Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.restaurant_menu)),
                      title: Text(m.name,
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      subtitle: m.description != null
                          ? Text(m.description!,
                              maxLines: 1, overflow: TextOverflow.ellipsis)
                          : null,
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () => setState(() => selected = m),
                    );
                  },
                ),
              )
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('Cancel')),
        ElevatedButton(
          onPressed: selected == null
              ? null
              : () => Navigator.of(context).pop(selected),
          child: const Text('Choose'),
        ),
      ],
    );
  }
}
