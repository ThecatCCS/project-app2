import 'dart:io';
import 'package:firebase_database/firebase_database.dart'; // Import Firebase Realtime Database
import 'package:firebase_image_upload/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart'; // Add this package to use maps
import 'package:latlong2/latlong.dart'; // To use LatLng for location

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
  String? _selectedValue; // Variable to hold the selected type
  final List<String> _options = ['rider', 'user']; // Dropdown options
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _vehicleNumberController =
      TextEditingController(); // For rider
  File? _image; // Variable to hold the picked image
  LatLng? _selectedLocation; // To store the user's selected location
  LatLng? _currentLocation; // Current device location

  @override
  void initState() {
    super.initState();
    _getCurrentPosition(); // Get the current position of the device
  }

  // ฟังก์ชันสำหรับรับตำแหน่งปัจจุบันของเครื่อง
  Future<void> _getCurrentPosition() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _selectedLocation =
          _currentLocation; // Set default marker to current location
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
              // Tap to upload profile image
              // Tap to upload profile image
              GestureDetector(
                onTap: () async {
                  final ImagePicker _picker = ImagePicker();
                  final XFile? image = await _picker.pickImage(
                      source: ImageSource
                          .camera); // เปลี่ยนเป็น ImageSource.camera เพื่อเปิดกล้อง
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
              // Phone Number Field
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
              // Password Field
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
              // Name Field
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
              // Dropdown
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
                    // If user is selected, load current location
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
              // Address for user
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
                      ? Center(
                          child:
                              CircularProgressIndicator()) // แสดงตัวโหลดขณะรอรับตำแหน่ง
                      : FlutterMap(
                          options: MapOptions(
                            center: _currentLocation, // ฟิกที่ตำแหน่งปัจจุบัน
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
              // Vehicle Number for rider
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
              // Sign Up Button
              ElevatedButton(
                onPressed: () {
                  // Handle sign up logic here, save data to Realtime Database
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
      // Create a reference to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref();
      final imageRef = storageRef
          .child('images/${DateTime.now().millisecondsSinceEpoch}.png');

      // Upload the image
      await imageRef.putFile(imageFile);

      // Get the download URL
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

    // Check if the necessary fields are filled
    if (phone.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    // Upload image if available
    String imageUrl = '';
    if (_image != null) {
      imageUrl = await _uploadImageToFirebase(_image!);
    }

    // Create a reference to the Realtime Database
    final databaseRef = FirebaseDatabase.instance.ref().child('users/$phone');

    // Example Realtime Database integration
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

      // Navigate back to login page
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const LoginPage()));
    } catch (e) {
      print("Error signing up: $e");
    }
  }
}
