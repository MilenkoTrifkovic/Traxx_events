// import 'package:firebase_auth/firebase_auth.dart};
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
// import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/controller/admin_controllers/host_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
import 'package:traxx_wepapp/services/shared_pref_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_theme.dart';
import 'package:traxx_wepapp/utils/navigation/app_router.dart';
import 'package:traxx_wepapp/services/firestore_services.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'firebase_options.dart';

//TODO
//after event is created, navigation to events doesn't work properly
//  Get.lazyPut<EventListController>(() => EventListController(), fenix: true); should not be here

//EventDetails back arrow doesn't work after reload - add check and pushRouted

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  setPathUrlStrategy();
  GoRouter.optionURLReflectsImperativeAPIs =
      true; //makes sure url is updated on navigation
  await dotenv.load(fileName: "dotenv");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // if (kDebugMode) {
  //   FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
  //   FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  //   FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  // }
  // Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  Get.lazyPut<SharedPrefServices>(() => SharedPrefServices(), fenix: true);
  Get.lazyPut<FirestoreServices>(() => FirestoreServices(), fenix: true);
  Get.lazyPut<StorageServices>(() => StorageServices(), fenix: true);
  Get.lazyPut<CloudFunctionsService>(() => CloudFunctionsService(),
      fenix: true);
  Get.lazyPut<EventListController>(() => EventListController(), fenix: true);
  Get.lazyPut<HostController>(() => HostController(), fenix: true);
  // Get.lazyPut<VenuesController>(() => VenuesController(), fenix: true);
  // Get.lazyPut<GuestController>(() => GuestController(), fenix: true);

  Get.put<EventController>(EventController(),
      permanent: true); //Holds selected event Event?
  final authController = Get.find<AuthController>();

  // Only check company info if user is authenticated and verified
  await authController.checkCompanyInfo();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      builder: EasyLoading.init(),
      theme: AppTheme.light,
      routerConfig: buildRouter(),
    );
  }
}
