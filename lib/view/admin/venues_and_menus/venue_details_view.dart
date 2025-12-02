// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:traxx_wepapp/controller/admin_controllers/venue_details_controller.dart';
// import 'package:traxx_wepapp/helper/app_spacing.dart';
// import 'package:traxx_wepapp/theme/app_colors.dart';
// import 'package:traxx_wepapp/theme/styled_app_text.dart';
// import 'package:traxx_wepapp/utils/enums/menu_category.dart';
// import 'package:traxx_wepapp/utils/loader.dart';
// import 'package:traxx_wepapp/widgets/app_dropdown_menu.dart';
// import 'package:traxx_wepapp/widgets/app_primary_button.dart';
// import 'package:traxx_wepapp/widgets/app_secondary_button.dart';
// import 'package:traxx_wepapp/widgets/app_text_input_field.dart';

// class VenueDetailsView extends StatefulWidget {
//   final String venueId;
//   const VenueDetailsView({super.key, required this.venueId});

//   @override
//   State<VenueDetailsView> createState() => _VenueDetailsViewState();
// }

// class _VenueDetailsViewState extends State<VenueDetailsView> {
//   late final VenueDetailsController controller;
//   bool isLoading = true;
//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     controller = VenueDetailsController();
//     controller.loadVenue(widget.venueId).then((_) {
//       setState(() {
//         isLoading = false;
//       });
//     });
//   }

//   @override
//   void dispose() {
//     controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       showLoadingIndicator();
//       // return const Center(child: CircularProgressIndicator());
//     }
//     hideLoadingIndicator();
//     if (controller.venue == null) {
//       return const Center(
//         child: Text(
//           'Venue not found.',
//           style: TextStyle(fontSize: 16, color: Color(0xFF374151)),
//         ),
//       );
//     }
//     final venue = controller.venue!;
//     return Padding(
//       padding: const EdgeInsets.all(24.0),
//       child: Column(
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               color: const Color(0xFFF0F0F0),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: const Color(0xFFA0A0A0)),
//             ),
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   venue.name ?? '-',
//                   style: const TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF111827),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 if (venue.description != null && venue.description!.isNotEmpty)
//                   Text(
//                     venue.description!,
//                     style:
//                         const TextStyle(fontSize: 16, color: Color(0xFF374151)),
//                   ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Venue ID: ${venue.organisationId ?? '-'}',
//                   style:
//                       const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
//                 ),
//                 if (venue.photoUrl != null && venue.photoUrl!.isNotEmpty) ...[
//                   const SizedBox(height: 16),
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: Image.network(
//                       venue.photoUrl!,
//                       height: 180,
//                       width: double.infinity,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) => Container(
//                         height: 180,
//                         color: const Color(0xFFEEF2F6),
//                         child: const Center(child: Icon(Icons.broken_image)),
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           const SizedBox(height: 24),
//           _buildMenuItemForm(context),
//         ],
//       ),
//     );
//   }

//   Widget _buildMenuItemForm(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(24.0),
//       decoration: BoxDecoration(
//         color: AppColors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: AppColors.borderHover),
//       ),
//       child: Form(
//         key: controller.menuFormKey,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             AppText.styledHeadingLarge(context, 'Create Menu Item'),
//             AppSpacing.verticalMd(context),
//             AppTextInputField(
//               label: 'Name *',
//               controller: controller.menuNameController,
//               hintText: 'Enter menu item name',
//               validator: controller.validateMenuName,
//               maxLength: 120,
//             ),
//             AppSpacing.verticalMd(context),
//             Obx(() => AppDropdownMenu<MenuCategory>(
//                   label: 'Category *',
//                   value: controller.selectedCategory.value,
//                   items: MenuCategory.values
//                       .map((category) => DropdownMenuItem<MenuCategory>(
//                             value: category,
//                             child: Text(_categoryLabel(category)),
//                           ))
//                       .toList(),
//                   onChanged: (value) {
//                     if (value != null) {
//                       controller.selectedCategory.value = value;
//                     }
//                   },
//                   validator: (value) =>
//                       value == null ? 'Please select a category' : null,
//                 )),
//             AppSpacing.verticalMd(context),
//             AppTextInputField(
//               label: 'Description (optional)',
//               controller: controller.menuDescriptionController,
//               hintText: 'Add a short description',
//               maxLines: 3,
//               validator: controller.validateMenuDescription,
//               maxLength: 500,
//             ),
//             AppSpacing.verticalMd(context),
//             _buildMenuImagePicker(context),
//             AppSpacing.verticalLg(context),
//             Row(
//               children: [
//                 Expanded(
//                   child: AppSecondaryButton(
//                     text: 'Clear',
//                     onPressed: controller.clearMenuForm,
//                   ),
//                 ),
//                 AppSpacing.horizontalMd(context),
//                 Expanded(
//                   child: Obx(() => AppPrimaryButton(
//                         text: controller.isCreatingMenuItem.value
//                             ? 'Creating...'
//                             : 'Create Menu Item',
//                         isLoading: controller.isCreatingMenuItem.value,
//                         onPressed: controller.isCreatingMenuItem.value
//                             ? null
//                             : () async {
//                                 await controller.submitMenuItem();
//                               },
//                       )),
//                 ),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMenuImagePicker(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         AppText.styledBodyLarge(
//           context,
//           'Photo (optional)',
//           weight: FontWeight.w600,
//         ),
//         AppSpacing.verticalSm(context),
//         Obx(() {
//           if (controller.selectedImage.value != null) {
//             return _buildSelectedImage(context);
//           }
//           return _buildImagePicker(context);
//         }),
//         Obx(() {
//           if (controller.imageError.value != null) {
//             return Padding(
//               padding: const EdgeInsets.only(top: 8.0),
//               child: Text(
//                 controller.imageError.value!,
//                 style: const TextStyle(color: Colors.red, fontSize: 12),
//               ),
//             );
//           }
//           return const SizedBox.shrink();
//         }),
//       ],
//     );
//   }

//   /// Builds the image picker widget
//   Widget _buildImagePicker(BuildContext context) {
//     return GestureDetector(
//       onTap: controller.pickImage,
//       child: Container(
//         width: double.infinity,
//         height: 200,
//         decoration: BoxDecoration(
//           color: AppColors.fofofo,
//           borderRadius: BorderRadius.circular(8.0),
//           border: Border.all(
//               color: AppColors.borderHover, style: BorderStyle.solid),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.cloud_upload_outlined,
//               size: 48,
//               color: AppColors.secondary,
//             ),
//             AppSpacing.verticalSm(context),
//             AppText.styledBodyMedium(
//               context,
//               'Click to upload menu item photo',
//               color: AppColors.secondary,
//             ),
//             AppSpacing.verticalXs(context),
//             AppText.styledBodySmall(
//               context,
//               'Supported formats: JPEG, PNG',
//               color: AppColors.secondary,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Builds the selected image preview
//   Widget _buildSelectedImage(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       height: 200,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(8.0),
//         border: Border.all(color: AppColors.borderHover),
//       ),
//       child: Stack(
//         children: [
//           ClipRRect(
//             borderRadius: BorderRadius.circular(8.0),
//             child: FutureBuilder<Uint8List>(
//               future: controller.selectedImage.value!.readAsBytes(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasData) {
//                   return Image.memory(
//                     snapshot.data!,
//                     width: double.infinity,
//                     height: 200,
//                     fit: BoxFit.cover,
//                   );
//                 } else {
//                   return Container(
//                     width: double.infinity,
//                     height: 200,
//                     color: AppColors.fofofo,
//                     child: const Center(
//                       child: CircularProgressIndicator(),
//                     ),
//                   );
//                 }
//               },
//             ),
//           ),
//           Positioned(
//             top: 8,
//             right: 8,
//             child: GestureDetector(
//               onTap: controller.removeImage,
//               child: Container(
//                 padding: const EdgeInsets.all(4),
//                 decoration: const BoxDecoration(
//                   color: Colors.red,
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.close,
//                   color: Colors.white,
//                   size: 16,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _categoryLabel(MenuCategory category) {
//     final name = category.name;
//     return name[0].toUpperCase() + name.substring(1);
//   }
// }

// // // import 'package:flutter/material.dart';
// // // import 'package:traxx_wepapp/utils/enums/menu_category.dart';

// // class MenuItemForm extends StatefulWidget {
// //   final void Function(String name, String description, MenuCategory category)
// //       onSubmit;

// //   const MenuItemForm({super.key, required this.onSubmit});

// //   @override
// //   State<MenuItemForm> createState() => _MenuItemFormState();
// // }

// // class _MenuItemFormState extends State<MenuItemForm> {
// //   final _formKey = GlobalKey<FormState>();
// //   final _nameController = TextEditingController();
// //   final _descriptionController = TextEditingController();
// //   MenuCategory? _selectedCategory;

// //   @override
// //   void dispose() {
// //     _nameController.dispose();
// //     _descriptionController.dispose();
// //     super.dispose();
// //   }

// //   void _submit() {
// //     if (_formKey.currentState?.validate() != true) return;
// //     if (_selectedCategory == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Please select a category')),
// //       );
// //       return;
// //     }
// //     widget.onSubmit(
// //       _nameController.text.trim(),
// //       _descriptionController.text.trim(),
// //       _selectedCategory!,
// //     );
// //     _formKey.currentState?.reset();
// //     setState(() {
// //       _selectedCategory = null;
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Form(
// //       key: _formKey,
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           const Text(
// //             'Create Menu Item',
// //             style: TextStyle(
// //               fontSize: 20,
// //               fontWeight: FontWeight.bold,
// //               color: Color(0xFF111827),
// //             ),
// //           ),
// //           const SizedBox(height: 24),
// //           TextFormField(
// //             controller: _nameController,
// //             decoration: const InputDecoration(
// //               labelText: 'Menu Item Name *',
// //               border: OutlineInputBorder(),
// //             ),
// //             validator: (value) {
// //               if (value == null || value.trim().isEmpty) {
// //                 return 'Name is required';
// //               }
// //               if (value.trim().length < 2) {
// //                 return 'Name must be at least 2 characters';
// //               }
// //               if (value.trim().length > 100) {
// //                 return 'Name must be less than 100 characters';
// //               }
// //               return null;
// //             },
// //           ),
// //           const SizedBox(height: 16),
// //           DropdownButtonFormField<MenuCategory>(
// //             initialValue: _selectedCategory,
// //             decoration: const InputDecoration(
// //               labelText: 'Category *',
// //               border: OutlineInputBorder(),
// //             ),
// //             items: MenuCategory.values
// //                 .map((cat) => DropdownMenuItem<MenuCategory>(
// //                       value: cat,
// //                       child: Text(cat.name),
// //                     ))
// //                 .toList(),
// //             onChanged: (cat) {
// //               setState(() {
// //                 _selectedCategory = cat;
// //               });
// //             },
// //             validator: (value) {
// //               if (value == null) {
// //                 return 'Category is required';
// //               }
// //               return null;
// //             },
// //           ),
// //           const SizedBox(height: 16),
// //           TextFormField(
// //             controller: _descriptionController,
// //             decoration: const InputDecoration(
// //               labelText: 'Description (Optional)',
// //               border: OutlineInputBorder(),
// //             ),
// //             maxLines: 3,
// //             validator: (value) {
// //               if (value != null && value.trim().length > 500) {
// //                 return 'Description must be less than 500 characters';
// //               }
// //               return null;
// //             },
// //           ),
// //           const SizedBox(height: 24),
// //           SizedBox(
// //             width: double.infinity,
// //             child: ElevatedButton(
// //               onPressed: _submit,
// //               child: const Text('Create Menu Item'),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
