import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_controller.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/controller/admin_controllers/host_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/guest_controllers/guest_session_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/services/shared_pref_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';
import 'package:traxx_wepapp/services/guest_firestore_services.dart';
import 'package:traxx_wepapp/theme/app_theme.dart';
import 'package:traxx_wepapp/utils/navigation/app_router.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:nominatim_geocoding/nominatim_geocoding.dart';

import 'firebase_options.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize date formatting for table_calendar locale support
  await initializeDateFormatting();
  
  tzdata.initializeTimeZones();
  setPathUrlStrategy();
  GoRouter.optionURLReflectsImperativeAPIs = true;

  await dotenv.load(fileName: "dotenv");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Nominatim Geocoding (works on web)
  await NominatimGeocoding.init(reqCacheNum: 50);

  Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
  Get.lazyPut<SharedPrefServices>(() => SharedPrefServices(), fenix: true);
  Get.lazyPut<FirestoreServices>(() => FirestoreServices(), fenix: true);
  Get.lazyPut<StorageServices>(() => StorageServices(), fenix: true);
  Get.lazyPut<CloudFunctionsService>(() => CloudFunctionsService(),
      fenix: true);
  Get.lazyPut<GuestFirestoreServices>(() => GuestFirestoreServices(),
      fenix: true);
  Get.lazyPut<EventListController>(() => EventListController(), fenix: true);
  Get.lazyPut<HostController>(() => HostController(), fenix: true);

  Get.put<EventController>(EventController(), permanent: true);

  // Initialize GuestSessionController to restore session if exists
  // This must happen BEFORE router is created so redirect guards can check authentication
  // Using putAsync ensures async session restoration completes before routing starts
  await Get.putAsync(() => GuestSessionController().init(), permanent: true);

  final authController = Get.find<AuthController>();

  // 🔄 read userRole + organisationId from /users/{uid} if logged in
  await authController.loadUserProfile();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SnackbarMessageController());

    return MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      // builder: EasyLoading.init(),
      builder: (context, child) {
        return EasyLoading.init()(context, child);
      },
      theme: AppTheme.light,
      routerConfig: buildRouter(),
    );
  }
}
