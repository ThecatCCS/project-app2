import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RiderProfilePage extends StatefulWidget {
  @override
  _RiderProfilePageState createState() => _RiderProfilePageState();
}

class _RiderProfilePageState extends State<RiderProfilePage> {
  final TextEditingController nameController = TextEditingController(text: 'John Doe');
  final TextEditingController phoneController = TextEditingController(text: '1234567890');
  final TextEditingController addressController = TextEditingController(text: '123 Main St');
  final TextEditingController licensePlateController = TextEditingController(text: 'AB-1234');
  
  File? _imageFile; // ตัวแปรสำหรับเก็บรูปถ่าย

  // ฟังก์ชันสำหรับถ่ายรูปทะเบียนรถ
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path); // บันทึกไฟล์รูป
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rider Profile'),
      ),
      body: SingleChildScrollView( // ใช้ SingleChildScrollView เพื่อแก้ปัญหาการ Overflow
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 50),

              // Avatar
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage('https://example.com/profile.jpg'), // เปลี่ยน URL ของรูปโปรไฟล์ได้
              ),
              SizedBox(height: 30),

              // ข้อมูลที่แสดงอยู่ใน TextField
              _buildProfileTextField('Name', nameController),
              SizedBox(height: 20),

              _buildProfileTextField('Phone', phoneController),
              SizedBox(height: 20),

              _buildProfileTextField('Address', addressController),
              SizedBox(height: 20),

              _buildProfileTextField('License Plate', licensePlateController),
              SizedBox(height: 20),

              // รูปทะเบียนรถ
              _imageFile == null
                  ? Text('No image selected.')
                  : Image.file(
                      _imageFile!,
                      width: 300,
                      height: 130,
                      fit: BoxFit.cover,
                    ),
              SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _pickImage, // ถ่ายรูปทะเบียนรถ
                icon: Icon(Icons.camera_alt),
                label: Text('ถ่ายรูปทะเบียนรถ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // สีพื้นหลังปุ่ม
                ),
              ),
              SizedBox(height: 30),

              // ปุ่มบันทึกข้อมูล
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('ยืนยันการบันทึก'),
                        content: Text('คุณต้องการบันทึกข้อมูลหรือไม่?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // ปิด dialog
                            },
                            child: Text('ยกเลิก'),
                          ),
                          TextButton(
                            onPressed: () {
                              // เพิ่มลอจิกสำหรับบันทึกข้อมูลที่นี่
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('ข้อมูลถูกบันทึกเรียบร้อยแล้ว!')),
                              );
                            },
                            child: Text('ยืนยัน'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // สีพื้นหลังปุ่ม
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget สำหรับสร้าง TextField พร้อม Label
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
