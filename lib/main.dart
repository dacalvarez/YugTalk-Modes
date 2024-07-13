import 'package:flutter/material.dart';
import 'package:device_preview_minus/device_preview_minus.dart';
import 'package:flutter/foundation.dart';  
import 'package:firebase_core/firebase_core.dart';
import 'package:test_drive/Screens/EditMode/EditMode.dart';
import 'package:test_drive/Screens/MeMode.dart';
import '../firebase_options.dart'; 

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => MaterialApp(
        title: "YugTalk App",
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: false,
        ),
        useInheritedMediaQuery: true, // keep this for device_preview to work
        home:  EditMode(userID: '1'), //temporary display for me mode module "const MeMode(userID: '1')"  or EditMode(userID: '2')
      ),
    ),
  );
}
