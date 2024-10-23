import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  LatLng? selectedLocation;
  LatLng? userLocation;
  LatLng? currentLocation;
  String phoneNumber = '';
  String? profileImageUrl;
  DatabaseReference _database = FirebaseDatabase.instance.ref();
  File? _imageFile; // For storing the selected image

  @override
  void initState() {
    super.initState();
    loadUserProfile(); // Load user profile from Firebase
  }

  // ฟังก์ชันสำหรับโหลดข้อมูลโปรไฟล์
  Future<void> loadUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    phoneNumber = prefs.getString('phone') ?? '';

    final snapshot = await _database.child('users/$phoneNumber').get();
    if (snapshot.exists) {
      Map<String, dynamic> userData = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        nameController.text = userData['name'] ?? 'No Name';
        addressController.text = userData['address'] ?? 'No Address';
        profileImageUrl = userData['imageUrl'];
        userLocation = LatLng(
          userData['location']['latitude'],
          userData['location']['longitude'],
        );
        selectedLocation = userLocation;
      });
    } else {
      _getCurrentLocation();
    }
  }

  // ฟังก์ชันสำหรับรับตำแหน่งปัจจุบัน
  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
      if (selectedLocation == null) {
        selectedLocation = currentLocation;
      }
    });
  }

  // ฟังก์ชันสำหรับอัปเดตโปรไฟล์ผู้ใช้ใน Firebase
  Future<void> updateUserProfile() async {
    if (phoneNumber.isNotEmpty) {
      // อัปโหลดรูปภาพถ้ามีการเลือกรูปใหม่
      String? newImageUrl;
      if (_imageFile != null) {
        newImageUrl = await _uploadImageToFirebase(_imageFile!);
      }

      await _database.child('users/$phoneNumber').update({
        'name': nameController.text,
        'address': addressController.text,
        'location': {
          'latitude': selectedLocation?.latitude ?? 0,
          'longitude': selectedLocation?.longitude ?? 0,
        },
        'imageUrl': newImageUrl ?? profileImageUrl, // ใช้รูปใหม่ถ้ามี หรือคงรูปเก่าไว้
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Profile updated successfully!'),
      ));
    }
  }

  // ฟังก์ชันสำหรับเปิดกล้องเพื่อถ่ายรูป
  Future<void> _pickImageFromCamera() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera); // เปิดกล้อง

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path); // บันทึกไฟล์รูปที่ถ่าย
      });
    }
  }

  // ฟังก์ชันสำหรับอัปโหลดรูปภาพไปยัง Firebase Storage
  Future<String> _uploadImageToFirebase(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef.child('profile_images/${DateTime.now().millisecondsSinceEpoch}.png');

      await imageRef.putFile(imageFile);
      String downloadUrl = await imageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImageFromCamera, // เปิดกล้องเมื่อกดที่รูปภาพ
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!) // แสดงรูปที่ถ่ายใหม่ถ้ามี
                    : profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : AssetImage('assets/default_profile.png') as ImageProvider,
              ),
            ),
                        SizedBox(height: 20),

            // Name TextField
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // Address TextField
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // แสดงแผนที่และตำแหน่ง
            Container(
              height: 300,
              width: double.infinity,
              child: userLocation == null
                  ? Center(child: CircularProgressIndicator())
                  : FlutterMap(
                      options: MapOptions(
                        center: selectedLocation ?? userLocation ?? LatLng(13.736717, 100.523186),
                        zoom: 13.0,
                        onTap: (tapPosition, point) {
                          setState(() {
                            selectedLocation = point; // เปลี่ยนตำแหน่งที่ผู้ใช้เลือก
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                          subdomains: ['a', 'b', 'c'],
                        ),
                        MarkerLayer(
                          markers: [
                            if (selectedLocation != null)
                              Marker(
                                width: 80.0,
                                height: 80.0,
                                point: selectedLocation!,
                                builder: (ctx) => Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            if (userLocation != null)
                              Marker(
                                width: 80.0,
                                height: 80.0,
                                point: userLocation!,
                                builder: (ctx) => Icon(
                                  Icons.location_pin,
                                  color: Colors.blue,
                                  size: 40,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
            ),
            SizedBox(height: 20),

            // Save Button
            ElevatedButton(
              onPressed: updateUserProfile,
              child: Text('บันทึก'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
