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
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';
import 'package:traxx_wepapp/services/shared_pref_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';
import 'package:traxx_wepapp/services/guest_firestore_services.dart';
import 'package:traxx_wepapp/theme/app_theme.dart';
import 'package:traxx_wepapp/theme/constants.dart';
import 'package:traxx_wepapp/utils/navigation/app_router.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:nominatim_geocoding/nominatim_geocoding.dart';
import 'package:flutter_stripe_web/flutter_stripe_web.dart';
import 'package:traxx_wepapp/theme/constants.dart';

import 'firebase_options.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting();
  tzdata.initializeTimeZones();
  setPathUrlStrategy();
  GoRouter.optionURLReflectsImperativeAPIs = true;

  try {
    await dotenv.load(fileName: "assets/dotenv");
  } catch (e) {
    debugPrint("⚠️ dotenv not loaded: $e");
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NominatimGeocoding.init(reqCacheNum: 50);

  Get.lazyPut<SharedPrefServices>(() => SharedPrefServices(), fenix: true);
  Get.lazyPut<FirestoreServices>(() => FirestoreServices(), fenix: true);
  Get.lazyPut<StorageServices>(() => StorageServices(), fenix: true);
  Get.lazyPut<CloudFunctionsService>(() => CloudFunctionsService(),
      fenix: true);
  Get.lazyPut<GuestFirestoreServices>(() => GuestFirestoreServices(),
      fenix: true);
  Get.lazyPut<EventListController>(() => EventListController(), fenix: true);
  Get.lazyPut<VenuesController>(() => VenuesController(), fenix: true);
  Get.lazyPut<HostController>(() => HostController(), fenix: true);

  Get.put<EventController>(EventController(), permanent: true);
  Get.put(SnackbarMessageController(), permanent: true);
  Get.put(AuthController(), permanent: true);

  await Get.putAsync(() => GuestSessionController().init(), permanent: true);

  // final authController = Get.find<AuthController>();
  // // await authController.loadUserProfile();
  await Constants.initAppInfo();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;
  late final TransitionBuilder _easyBuilder;

  @override
  void initState() {
    super.initState();
    _router = buildRouter(); // ✅ once
    _easyBuilder = EasyLoading.init(); // ✅ once
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Trax Events',
      theme: AppTheme.light,
      builder: _easyBuilder, // ✅ use cached builder
      routerConfig: _router, // ✅ use cached router
    );
  }
}
