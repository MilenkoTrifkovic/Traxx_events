// import 'package:flutter/material.dart';
// import 'package:traxx_wepapp/helper/validation_helper.dart';

// class OrganisationAddress extends StatelessWidget {
//   final TextEditingController streetController;
//   final TextEditingController cityController;
//   final TextEditingController stateController;
//   final TextEditingController zipController;
//   final TextEditingController countryController;
//   final TextEditingController websiteController;
//   const OrganisationAddress(
//       {super.key,
//       required this.streetController,
//       required this.cityController,
//       required this.stateController,
//       required this.zipController,
//       required this.countryController,
//       required this.websiteController});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         TextFormField(
//           controller: streetController,
//           decoration: const InputDecoration(
//             labelText: 'Street Address *',
//             border: OutlineInputBorder(),
//           ),
//           validator: (value) =>
//               ValidationHelper.validateRequired(value, 'Street Address'),
//         ),
//         const SizedBox(height: 16),
//         Row(
//           children: [
//             Expanded(
//               child: TextFormField(
//                 controller: cityController,
//                 decoration: const InputDecoration(
//                   labelText: 'City *',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) =>
//                     ValidationHelper.validateRequired(value, 'City'),
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: TextFormField(
//                 controller: stateController,
//                 decoration: const InputDecoration(
//                   labelText: 'State *',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) =>
//                     ValidationHelper.validateRequired(value, 'State'),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),
//         Row(
//           children: [
//             Expanded(
//               child: TextFormField(
//                 controller: zipController,
//                 decoration: const InputDecoration(
//                   labelText: 'Zip / Postal Code *',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) =>
//                     ValidationHelper.validateRequired(value, 'Zip Code'),
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: TextFormField(
//                 controller: countryController,
//                 decoration: const InputDecoration(
//                   labelText: 'Country *',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) =>
//                     ValidationHelper.validateRequired(value, 'Country'),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),
//         TextFormField(
//           controller: websiteController,
//           decoration: const InputDecoration(
//             labelText: 'Website',
//             border: OutlineInputBorder(),
//             hintText: 'https://example.com',
//           ),
//           keyboardType: TextInputType.url,
//           validator: (value) => ValidationHelper.validateWebsite(value),
//         ),
//       ],
//     );
//   }
// }
