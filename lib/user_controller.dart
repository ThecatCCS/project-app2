import 'package:get/get.dart';

class UserController extends GetxController {
  var phone = ''.obs; // Observable สำหรับหมายเลขโทรศัพท์
  var userType = ''.obs;

  get selectedIndex => null; // Observable สำหรับประเภทผู้ใช้

  void setUser(String newPhone, String newUserType) {
    phone.value = newPhone;
    userType.value = newUserType;
  }
}
