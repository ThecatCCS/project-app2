import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  LatLng? selectedLocation;
  LatLng? userLocation; // ตำแหน่งที่ดึงมาจาก Firebase
  LatLng? currentLocation; // ตำแหน่งปัจจุบันของอุปกรณ์
  String phoneNumber = '';
  String? profileImageUrl;
  DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    loadUserProfile(); // โหลดโปรไฟล์จาก Firebase
  }

  Future<void> loadUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    phoneNumber = prefs.getString('phone') ?? '';

    // ดึงข้อมูลโปรไฟล์ผู้ใช้จาก Firebase
    final snapshot = await _database.child('users/$phoneNumber').get();
    if (snapshot.exists) {
      Map<String, dynamic> userData =
          Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        nameController.text = userData['name'] ?? 'No Name';
        addressController.text = userData['address'] ?? 'No Address';
        profileImageUrl = userData['imageUrl'];
        userLocation = LatLng(
          userData['location']['latitude'],
          userData['location']['longitude'],
        ); // ใช้ตำแหน่งจาก Firebase
        selectedLocation =
            userLocation; // ตั้งตำแหน่งที่ผู้ใช้เลือกเป็นตำแหน่งในฐานข้อมูล
      });
    } else {
      _getCurrentLocation(); // ถ้าไม่มีข้อมูลใน Firebase ให้ใช้ตำแหน่งปัจจุบัน
    }
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
      if (selectedLocation == null) {
        selectedLocation =
            currentLocation; // ถ้าไม่มีตำแหน่งที่บันทึกไว้ ใช้ตำแหน่งปัจจุบัน
      }
    });
  }

  Future<void> updateUserProfile() async {
    if (phoneNumber.isNotEmpty) {
      await _database.child('users/$phoneNumber').update({
        'name': nameController.text,
        'address': addressController.text,
        'location': {
          'latitude': selectedLocation?.latitude ?? 0,
          'longitude': selectedLocation?.longitude ?? 0,
        },
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Profile updated successfully!'),
      ));
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
              onTap: () {
                // Add functionality for picking a profile image if needed
              },
              child: CircleAvatar(
                radius: 50,
                backgroundImage: profileImageUrl != null
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

            // แสดงแผนที่โดยเริ่มต้นที่ตำแหน่งใน Firebase ถ้ามี หรือใช้ตำแหน่งปัจจุบัน
            Container(
              height: 300,
              width: double.infinity,
              child: userLocation == null
                  ? Center(
                      child:
                          CircularProgressIndicator()) // แสดง loading ถ้ายังไม่ได้ตำแหน่ง
                  : FlutterMap(
                      options: MapOptions(
                        center: selectedLocation ??
                            userLocation ??
                            LatLng(13.736717,
                                100.523186), // ใช้ตำแหน่งจาก Firebase หรือปัจจุบัน
                        zoom: 13.0,
                        onTap: (tapPosition, point) {
                          setState(() {
                            selectedLocation =
                                point; // เปลี่ยนตำแหน่งที่ผู้ใช้เลือก
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
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
                            // Marker ที่แสดงตำแหน่งปัจจุบันของผู้ใช้จาก Firebase
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
