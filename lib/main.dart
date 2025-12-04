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
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/services/shared_pref_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';
import 'package:traxx_wepapp/theme/app_theme.dart';
import 'package:traxx_wepapp/utils/enums/snack_bar_type.dart';
import 'package:traxx_wepapp/utils/navigation/app_router.dart';
import 'package:traxx_wepapp/services/firestore_services.dart';
import 'package:traxx_wepapp/utils/snackbar_utils.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'firebase_options.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

//TODO
//after event is created, navigation to events doesn't work properly
//  Get.lazyPut<EventListController>(() => EventListController(), fenix: true); should not be here

//EventDetails back arrow doesn't work after reload - add check and pushRouted

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  setPathUrlStrategy();
  GoRouter.optionURLReflectsImperativeAPIs = true;

  await dotenv.load(fileName: "dotenv");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  Get.lazyPut<SharedPrefServices>(() => SharedPrefServices(), fenix: true);
  Get.lazyPut<FirestoreServices>(() => FirestoreServices(), fenix: true);
  Get.lazyPut<StorageServices>(() => StorageServices(), fenix: true);
  Get.lazyPut<CloudFunctionsService>(() => CloudFunctionsService(),
      fenix: true);
  Get.lazyPut<EventListController>(() => EventListController(), fenix: true);
  Get.lazyPut<HostController>(() => HostController(), fenix: true);

  Get.put<EventController>(EventController(), permanent: true);

  final authController = Get.find<AuthController>();

  // 🔄 read userRole + organisationId from /users/{uid} if logged in
  await authController.loadUserProfile();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    final snackbarController = Get.put(SnackbarMessageController());

    return MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      // builder: EasyLoading.init(),
      builder: (context, child) {
        // GLOBAL LISTENER
        // ever(snackbarController.message, (msg) {
        //   if (msg == null) return;

        //   if (msg.type == SnackBarType.success) {
        //     SnackBarUtils.showSuccess(context, msg.message);
        //   } else {
        //     SnackBarUtils.showError(context, msg.message);
        //   }

        //   snackbarController.clearMessage();
        // });

        return EasyLoading.init()(context, child);
      },
      theme: AppTheme.light,
      routerConfig: buildRouter(),
    );
  }
}
