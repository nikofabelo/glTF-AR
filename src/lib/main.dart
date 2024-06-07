import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final arCoreAvailable = await ArCoreController.checkArCoreAvailability();
  final arCoreInstalled = await ArCoreController.checkIsArCoreInstalled();

  if (arCoreAvailable && arCoreInstalled) {
    runApp(const App());
  } else {
    Fluttertoast.showToast(
      msg: 'AR Features are unavailable!',
      toastLength: Toast.LENGTH_LONG
    );

    Future.delayed(const Duration(seconds: 3), () {
      SystemNavigator.pop();
    });
  }
}