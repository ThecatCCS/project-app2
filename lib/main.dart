import 'package:firebase_image_upload/pages/login.dart';
import 'package:firebase_image_upload/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart'; // นำเข้า Firebase Core

Future<void> main() async {
  Get.put(UserController()); // ลงทะเบียน UserController
  WidgetsFlutterBinding.ensureInitialized(); // ทำให้แน่ใจว่า Flutter ได้ถูก initialize ก่อน
  await Firebase.initializeApp(); // เริ่มต้นใช้งาน Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App',
      home: LoginPage(),
    );
  }
}
