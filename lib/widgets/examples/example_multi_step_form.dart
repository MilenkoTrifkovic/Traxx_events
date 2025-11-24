// import 'package:flutter/material.dart';
// import 'package:traxx_wepapp/models/form_step_model.dart';
// import 'package:traxx_wepapp/widgets/multi_step_form_widget.dart';

// /// Example usage of the new MultiStepFormWidget
// class ExampleMultiStepForm extends StatelessWidget {
//   const ExampleMultiStepForm({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiStepFormWidget(
//       steps: _createFormSteps(),
//       onSubmit: _handleFormSubmit,
//       stepIndicatorsBuilder: (controller) =>
//           _buildCustomStepIndicators(controller),
//       // navigationButtonsBuilder: (controller) => _buildCustomNavigationButtons(controller), // Optional
//     );
//   }

//   List<FormStepModel> _createFormSteps() {
//     return [
//       FormStepModel(
//         title: 'Basic Information',
//         description: 'Enter your basic details',
//         icon: Icons.person,
//         form: _buildStep1Form(),
//         onContinue: _validateStep1,
//       ),
//       FormStepModel(
//         title: 'Contact Details',
//         description: 'Provide your contact information',
//         icon: Icons.contact_phone,
//         form: _buildStep2Form(),
//         onContinue: _validateStep2,
//       ),
//       FormStepModel(
//         title: 'Preferences',
//         description: 'Set your preferences',
//         icon: Icons.settings,
//         form: _buildStep3Form(),
//         onContinue: _validateStep3,
//       ),
//     ];
//   }

//   Widget _buildStep1Form() {
//     return Column(
//       children: [
//         const Text('Step 1: Basic Information',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//         const SizedBox(height: 16),
//         const TextField(
//           decoration: InputDecoration(
//             labelText: 'First Name',
//             border: OutlineInputBorder(),
//           ),
//         ),
//         const SizedBox(height: 16),
//         const TextField(
//           decoration: InputDecoration(
//             labelText: 'Last Name',
//             border: OutlineInputBorder(),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStep2Form() {
//     return Column(
//       children: [
//         const Text('Step 2: Contact Details',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//         const SizedBox(height: 16),
//         const TextField(
//           decoration: InputDecoration(
//             labelText: 'Email',
//             border: OutlineInputBorder(),
//           ),
//         ),
//         const SizedBox(height: 16),
//         const TextField(
//           decoration: InputDecoration(
//             labelText: 'Phone',
//             border: OutlineInputBorder(),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStep3Form() {
//     return Column(
//       children: [
//         const Text('Step 3: Preferences',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//         const SizedBox(height: 16),
//         CheckboxListTile(
//           title: const Text('Subscribe to newsletter'),
//           value: true,
//           onChanged: (value) {},
//         ),
//         CheckboxListTile(
//           title: const Text('Enable notifications'),
//           value: false,
//           onChanged: (value) {},
//         ),
//       ],
//     );
//   }

//   bool _validateStep1() {
//     // Add your validation logic here
//     print('Validating Step 1');
//     // Return true if validation passes, false otherwise
//     return true;
//   }

//   bool _validateStep2() {
//     // Add your validation logic here
//     print('Validating Step 2');
//     return true;
//   }

//   bool _validateStep3() {
//     // Add your validation logic here
//     print('Validating Step 3');
//     return true;
//   }

//   Future<void> _handleFormSubmit() async {
//     // Handle the final form submission
//     print('Submitting form...');

//     // Simulate API call
//     await Future.delayed(const Duration(seconds: 2));

//     print('Form submitted successfully!');
//     // Navigate to success page or show success message
//   }

//   Widget _buildCustomStepIndicators(controller) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: List.generate(controller.totalSteps, (index) {
//         final step = controller.steps[index];
//         final isActive = index == controller.currentStep;
//         final isCompleted = index < controller.currentStep;

//         return Container(
//           margin: const EdgeInsets.symmetric(horizontal: 8),
//           child: Column(
//             children: [
//               Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: isCompleted
//                       ? Colors.green
//                       : isActive
//                           ? Colors.blue
//                           : Colors.grey[300],
//                 ),
//                 child: Icon(
//                   step.icon ?? Icons.check,
//                   color: isCompleted || isActive ? Colors.white : Colors.grey,
//                   size: 20,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               if (step.title != null)
//                 Text(
//                   step.title!,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: isActive ? Colors.blue : Colors.grey,
//                     fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
//                   ),
//                 ),
//             ],
//           ),
//         );
//       }),
//     );
//   }
// }
