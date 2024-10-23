import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_image_upload/pages/login.dart';

class SignUpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SignUpForm(),
    );
  }
}

class SignUpForm extends StatefulWidget {
  const SignUpForm({Key? key}) : super(key: key);

  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  String? _selectedValue; // ตัวแปรสำหรับเลือกประเภท user/rider
  final List<String> _options = ['rider', 'user']; // ตัวเลือกประเภท
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _vehicleNumberController =
      TextEditingController(); // สำหรับ rider
  File? _image; // ตัวแปรสำหรับเก็บรูปที่ถ่าย
  LatLng? _selectedLocation; // ตัวแปรเก็บตำแหน่งที่เลือกบนแผนที่
  LatLng? _currentLocation; // ตัวแปรเก็บตำแหน่งปัจจุบันของเครื่อง

  @override
  void initState() {
    super.initState();
    _getCurrentPosition(); // เรียกฟังก์ชันหาตำแหน่งปัจจุบัน
  }

  // ฟังก์ชันสำหรับหาตำแหน่งปัจจุบันของเครื่อง
Future<void> _getCurrentPosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // ตรวจสอบว่าเปิดใช้งานบริการตำแหน่งหรือไม่
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // หากไม่ได้เปิดใช้งานบริการตำแหน่ง ให้แสดงข้อความแจ้งผู้ใช้
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Location services are disabled. Please enable the services'),
    ));
    return;
  }

  // ตรวจสอบสิทธิ์การเข้าถึงตำแหน่ง
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // หากผู้ใช้ปฏิเสธการให้สิทธิ์
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Location permissions are denied'),
      ));
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // หากผู้ใช้ปฏิเสธการให้สิทธิ์อย่างถาวร
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Location permissions are permanently denied, we cannot request permissions.'),
    ));
    return;
  }

  // เมื่อได้สิทธิ์เรียบร้อย ให้ดึงตำแหน่งปัจจุบัน
  Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);

  setState(() {
    _currentLocation = LatLng(position.latitude, position.longitude);
    _selectedLocation = _currentLocation; // กำหนดตำแหน่งปัจจุบันเป็นตำแหน่งที่เลือกเริ่มต้น
  });
}


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Sign Up',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 40,
                ),
              ),
              const SizedBox(height: 30),
              // ถ่ายรูปโปรไฟล์
              GestureDetector(
                onTap: () async {
                  final ImagePicker _picker = ImagePicker();
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() {
                      _image = File(image.path);
                    });
                  }
                },
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _image != null ? FileImage(_image!) : null,
                  child: _image == null
                      ? Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(height: 30),
              // ฟิลด์เบอร์โทรศัพท์
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: const TextStyle(
                    color: Color.fromARGB(255, 75, 161, 72),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              // ฟิลด์รหัสผ่าน
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(
                    color: Color.fromARGB(255, 75, 161, 72),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              // ฟิลด์ชื่อ
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: const TextStyle(
                    color: Color.fromARGB(255, 75, 161, 72),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              // ตัวเลือกประเภท user/rider
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Type',
                  labelStyle: const TextStyle(
                    color: Color.fromARGB(255, 75, 161, 72),
                  ),
                  border: const OutlineInputBorder(),
                ),
                value: _selectedValue,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedValue = newValue;
                    // ถ้าเลือก user ให้แสดงตำแหน่งปัจจุบัน
                    if (_selectedValue == 'user' && _currentLocation != null) {
                      _selectedLocation = _currentLocation;
                    }
                  });
                },
                items: _options.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // สำหรับ user: ฟิลด์ที่อยู่ และการเลือกตำแหน่ง
              if (_selectedValue == 'user') ...[
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    labelStyle: const TextStyle(
                      color: Color.fromARGB(255, 75, 161, 72),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Select Your Location:',
                  style: TextStyle(
                    color: Color.fromARGB(255, 75, 161, 72),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 200,
                  width: double.infinity,
                  child: _currentLocation == null
                      ? Center(child: CircularProgressIndicator())
                      : FlutterMap(
                          options: MapOptions(
                            center: _selectedLocation ??
                                _currentLocation, // ฟิกที่ตำแหน่งปัจจุบัน
                            zoom: 13.0,
                            onTap: (tapPosition, LatLng point) {
                              setState(() {
                                _selectedLocation = point;
                              });
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                              subdomains: ['a', 'b', 'c'],
                            ),
                            if (_selectedLocation != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    width: 80.0,
                                    height: 80.0,
                                    point: _selectedLocation!,
                                    builder: (ctx) => const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                ),
              ],
              // สำหรับ rider: ฟิลด์หมายเลขทะเบียนรถ
              if (_selectedValue == 'rider') ...[
                TextField(
                  controller: _vehicleNumberController,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Number',
                    labelStyle: const TextStyle(
                      color: Color.fromARGB(255, 75, 161, 72),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 50),
              // ปุ่มลงทะเบียน
              ElevatedButton(
                onPressed: () {
                  // ดำเนินการลงทะเบียน
                  _signUp(context);
                },
                child: const Text('Sign up'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(10),
                  backgroundColor: const Color.fromARGB(255, 75, 161, 72),
                  minimumSize: const Size(260, 80),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Have an account yet?'),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      'Sign in',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _uploadImageToFirebase(File imageFile) async {
    try {
      // อัพโหลดรูปภาพไปยัง Firebase Storage
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef
          .child('images/${DateTime.now().millisecondsSinceEpoch}.png');

      await imageRef.putFile(imageFile);
      String downloadUrl = await imageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return '';
    }
  }

  void _signUp(BuildContext context) async {
    String phone = _phoneController.text;
    String password = _passwordController.text;
    String name = _nameController.text;
    String address = _addressController.text;
    String vehicleNumber = _vehicleNumberController.text;

    // ตรวจสอบว่าได้กรอกข้อมูลครบหรือไม่
    if (phone.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    // อัพโหลดรูปโปรไฟล์ถ้ามี
    String imageUrl = '';
    if (_image != null) {
      imageUrl = await _uploadImageToFirebase(_image!);
    }

    // บันทึกข้อมูลผู้ใช้ไปยัง Firebase Realtime Database
    final databaseRef = FirebaseDatabase.instance.ref().child('users/$phone');
    try {
      await databaseRef.set({
        'phone': phone,
        'password': password,
        'name': name,
        'address': _selectedValue == 'user' ? address : null,
        'type': _selectedValue,
        'location': _selectedValue == 'user'
            ? {
                'latitude': _selectedLocation!.latitude,
                'longitude': _selectedLocation!.longitude
              }
            : null,
        'vehicleNumber': _selectedValue == 'rider' ? vehicleNumber : null,
        'imageUrl': imageUrl,
      });
      print("User signed up successfully.");

      // ไปหน้า Login หลังจากลงทะเบียนเสร็จ
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const LoginPage()));
    } catch (e) {
      print("Error signing up: $e");
    }
  }
}
