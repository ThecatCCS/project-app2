import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RiderProfilePage extends StatefulWidget {
  @override
  _RiderProfilePageState createState() => _RiderProfilePageState();
}

class _RiderProfilePageState extends State<RiderProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController licensePlateController = TextEditingController();
  File? _profileImage; // สำหรับเก็บรูปโปรไฟล์
  String phoneNumber = ''; // สำหรับเก็บหมายเลขโทรศัพท์ของผู้ใช้งาน
  DatabaseReference _database = FirebaseDatabase.instance.ref(); // Realtime Database Reference
  String? profileImageUrl; // URL ของรูปโปรไฟล์จาก Realtime Database

  @override
  void initState() {
    super.initState();
    _fetchRiderInfo(); // ดึงข้อมูลผู้ขับขี่จาก Realtime Database
  }

  // ฟังก์ชันดึงข้อมูลจาก Realtime Database
  Future<void> _fetchRiderInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    phoneNumber = prefs.getString('phone') ?? '';

    final snapshot = await _database.child('users/$phoneNumber').get();
    if (snapshot.exists) {
      Map<String, dynamic> riderData = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        nameController.text = riderData['name'] ?? '';
        licensePlateController.text = riderData['vehicleNumber'] ?? '';
        profileImageUrl = riderData['imageUrl']; // ดึง URL รูปจาก Realtime Database
      });
    }
  }

  // ฟังก์ชันอัปโหลดรูปโปรไฟล์ไปยัง Firebase Storage
  Future<String> _uploadProfileImage(File image) async {
    try {
      String fileName = 'profileImages/$phoneNumber';
      Reference firebaseStorageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = firebaseStorageRef.putFile(image);
      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL(); // คืนค่า URL หลังจากอัปโหลดเสร็จสิ้น
    } catch (e) {
      throw Exception("Failed to upload image: $e");
    }
  }

  // ฟังก์ชันบันทึกข้อมูลไปยัง Realtime Database
  Future<void> _saveRiderInfo() async {
    if (phoneNumber.isEmpty) return;

    Map<String, dynamic> updatedData = {
      'name': nameController.text,
      'vehicleNumber': licensePlateController.text,
    };

    if (_profileImage != null) {
      String imageUrl = await _uploadProfileImage(_profileImage!);
      updatedData['imageUrl'] = imageUrl; // เพิ่ม URL รูปภาพลงใน Realtime Database
    }

    await _database.child('users/$phoneNumber').update(updatedData); // อัปเดตข้อมูลใน Realtime Database
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ข้อมูลถูกบันทึกเรียบร้อยแล้ว!')),
    );
  }

  // ฟังก์ชันสำหรับถ่ายรูปโปรไฟล์
  Future<void> _pickProfileImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rider Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 50),

              // Avatar สำหรับรูปโปรไฟล์
              GestureDetector(
                onTap: _pickProfileImage, // กดเพื่อถ่ายรูปใหม่
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : profileImageUrl != null
                          ? NetworkImage(profileImageUrl!)
                          : AssetImage('assets/default_profile.png') as ImageProvider,
                ),
              ),
              SizedBox(height: 30),

              // ฟิลด์สำหรับแสดงและแก้ไขข้อมูลชื่อและหมายเลขทะเบียนรถ
              _buildProfileTextField('Name', nameController),
              SizedBox(height: 20),
              _buildProfileTextField('License Plate', licensePlateController),
              SizedBox(height: 20),

              // ปุ่มบันทึกข้อมูล
              ElevatedButton(
                onPressed: _saveRiderInfo, // เรียกฟังก์ชันบันทึกข้อมูล
                child: Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ฟังก์ชันสร้าง TextField พร้อม Label
  Widget _buildProfileTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color.fromARGB(255, 75, 161, 72)),
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromARGB(255, 75, 161, 72), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromARGB(255, 75, 161, 72)),
        ),
      ),
    );
  }
}
